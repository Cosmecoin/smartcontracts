pragma solidity 0.4.19;

import './COSToken.sol';
import './COSTeamWallet.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract COSCrowdSale is Ownable{
  using SafeMath for uint256;

  uint256 constant internal MIN_CONTRIBUTION = 1 ether;
  uint256 constant internal TOKEN_DECIMALS = 10**10;
  uint256 constant internal ETH_DECIMALS = 10**18;
  uint8 constant internal TIERS = 6;
  uint8 constant internal BONUS_TIER = 1;
  uint256 private bonusCounter;
  uint256 public tknsPerPerson;
  uint256 public icoEndTime;
  uint256 public weiRaised;
  uint256 public ethPrice;
  address public holdings;
  address public owner;
  uint256 public cap;
  uint8 private tier;
  bool private paused;
  bool public tknsCalculated;

  enum Status {
    New, Approved, Denied
  }

  struct Participant {
    uint256 contrAmount;
    uint256 qtyTokens;
    uint256 remainingWei;
    uint8 tierPurchased;
    bool bonusPaid;
    Status whitelistStatus;
  }

  mapping(address => Participant) public participants;

  //The Cosmocoin token and team wallet contracts
  COSToken public cosToken;
  COSTeamWallet public cosTeamWallet; 

  struct SaleTier {      
    uint256 tokensToBeSold;  //amount of tokens to be sold in this SaleTier
    uint256 tokensSold;      //amount of tokens sold in each SaleTier     
  }
   
  mapping(uint8 => SaleTier) saleTier;

  event LogTokensTransferedFrom(address _owner, address _msgsender, uint256 _qtyOfTokensRequested);
  event LogTokensReserved(address _buyer, uint256 _amount);
  event LogWithdrawal(address _investor, uint256 _amount);
  event LogBonusRedeemed(address _participant, uint256 _amountTkns); 
 
  modifier isValidPayload() {
    require(msg.data.length == 0 || msg.data.length == 4); // double check this one
    _;
  }

  modifier icoIsActive() {
    require(weiRaised < cap && now < icoEndTime && calculateRemainingTokens() > 0);
    _;
  }

  modifier icoHasEnded() {
    require(weiRaised >= cap || now > icoEndTime || calculateRemainingTokens() == 0);
    _;
  }

  modifier activeContract(){
    require(paused == false);
    _;
  }

  /// @dev confirm price thresholds and amounts
  ///  holdings for holding ether
  ///  COSToken token address pushed to mainnet first
  function COSCrowdSale(address _holdings, address _cosToken, address _teamWallet) 
    public 
  {
    require(_holdings != 0x0);
    require(_cosToken != 0x0);
    require(_teamWallet != 0x0);     
 
    icoEndTime = now + 60 days;
    cosTeamWallet = COSTeamWallet(_teamWallet);
    weiRaised = 0;
    cosToken = COSToken(_cosToken);    
    holdings = _holdings;
    owner = msg.sender;
    cap = 7812.5 ether;

    saleTier[0].tokensToBeSold = (12500000)*TOKEN_DECIMALS;
   
   for(uint8 i=1; i<TIERS; i++){ 
    saleTier[i].tokensToBeSold = (37500000)*TOKEN_DECIMALS;
   } 
 }

  /// @dev Fallback function.
  /// @dev Reject random ethereum being sent to the contract.
  /// @notice allows for owner to send ethereum to the contract in the event
  /// of a refund
  function()
    public
    payable
  {
    require(msg.sender == owner);
  }

  /// @notice buyer calls this function to order to get on the list for approval
  /// buyers must send the ether with their whitelist application
  function buyTokens()
    external
    payable
    icoIsActive
    activeContract
    isValidPayload
    
    returns (uint8)
  {
    
    Participant storage participant = participants[msg.sender];

    require(msg.sender != owner);
    require(ethPrice != 0);
    require(participant.whitelistStatus != Status.Denied);
    require(msg.value.add(participant.remainingWei) >= MIN_CONTRIBUTION);

    if(participant.contrAmount == 0){
      participant.tierPurchased = tier; 
    } 

    uint256 remainingWei = msg.value.add(participant.remainingWei);
    participant.remainingWei = 0;
    uint256 totalTokensRequested;
    uint256 price = (ETH_DECIMALS.mul(uint256(20+(4*tier))).div(1000)).div(ethPrice);
    uint256 tierRemainingTokens;
    uint256 tknsRequested;
  
    while(remainingWei >= price && tier != TIERS) {

      SaleTier storage tiers = saleTier[tier];
      price = (ETH_DECIMALS.mul(uint256(20+(4*tier))).div(1000)).div(ethPrice);
      tknsRequested = (remainingWei.div(price)).mul(TOKEN_DECIMALS);
      tierRemainingTokens = tiers.tokensToBeSold.sub(tiers.tokensSold);
      if(tknsRequested >= tierRemainingTokens){
        tknsRequested -= tierRemainingTokens;
        tiers.tokensSold += tierRemainingTokens;
        totalTokensRequested += tierRemainingTokens;
        remainingWei -= ((tierRemainingTokens.mul(price)).div(TOKEN_DECIMALS));
        tier++;
      } else{
        tiers.tokensSold += tknsRequested;
        totalTokensRequested += tknsRequested;
        remainingWei -= ((tknsRequested.mul(price)).div(TOKEN_DECIMALS));
      }  
    }

    uint256 amount = msg.value.sub(remainingWei);
    weiRaised += amount;
    participant.remainingWei += remainingWei;
    participant.contrAmount += amount;
    participant.qtyTokens += totalTokensRequested;
    LogTokensReserved(msg.sender, totalTokensRequested);
    
    return tier;
  }

  ///@notice I want to get the price of ethereum every time I call the buy tokens function
  ///what has to change in this function to make that happen safely
  ///param ethereum price will exclude decimals
  function setEtherPrice(uint256 _price)
    external
    onlyOwner
    {
      ethPrice = _price;
    }

  ///@notice interface for founders to whitelist participants
  function approveAddressForWhitelist(address _address) 
    public 
    onlyOwner
    icoHasEnded 
    {
      require(_address != address(0));
      Participant storage participant = participants[_address];
      participant.whitelistStatus = Status.Approved;
      if(participant.tierPurchased <= BONUS_TIER){
        bonusCounter++;
      }
    }

  ///@notice interface for founders to whitelist participants
  function denyAddressForWhitelist(address _address) 
    public 
    onlyOwner
    icoHasEnded 
    {
      require(_address != address(0));
      participants[_address].whitelistStatus = Status.Denied;
    }

  /// @notice pause specific funtions of the contract
  function pauseContract() public onlyOwner {
    paused = true;
  }

  /// @notice to unpause functions
  function unpauseContract() public onlyOwner {
    paused = false;
  } 

  function checkContributorStatus()
    view
    public
    returns (bool whitelisted, bool bonusTier)
  {
    Participant storage participant = participants[msg.sender];
    return (participant.whitelistStatus == Status.Approved, participant.tierPurchased <= BONUS_TIER);
  }     

  ///@notice owner withdraws ether periodically from the crowdsale contract
  function ownerWithdrawal()
    public
    onlyOwner
    returns(bool success)
  {
    LogWithdrawal(msg.sender, this.balance);//do we really want to broadcast this
    holdings.transfer(this.balance);
    return(true); 
  }

  /// @dev freeze unsold tokens for use at a later time
  /// and transfer team, owner and other internally promised tokens
  /// param total number of tokens being transfered to the freeze wallet
  function finalize(uint256 _internalTokens)
    public
    icoHasEnded
    onlyOwner
  {
    cosTeamWallet.setFreezeTime(now);
    cosToken.transferFrom(owner, cosTeamWallet, _internalTokens);
  }

  /// @notice calculate unsold tokens for transfer to holdings to be used at a later date
  function calculateRemainingTokens()
    view
    internal
    returns (uint256)
  {
    uint256 remainingTokens;
    for(uint8 i = 0; i < TIERS; i++){
      if(saleTier[i].tokensSold < saleTier[i].tokensToBeSold){
        remainingTokens += saleTier[i].tokensToBeSold.sub(saleTier[i].tokensSold);
      }
    }
    return remainingTokens;
  }

  ///param total number of whitelist participants collected from the final count in the database
  ///manually entered here tokens will be then be available for collection by the qualified participants
  function distributeRemainingTokens()
    public
    icoHasEnded
    onlyOwner
    returns(bool success)
  {
    require(calculateRemainingTokens() > 20000*TOKEN_DECIMALS);
    uint256 bonusDistribution = calculateRemainingTokens().div(2); //split evenly between participants and reserve  
    tknsPerPerson = bonusDistribution.div(bonusCounter);
    tknsCalculated = true;
    return true;   
  }

  /// notice sends requested tokens to the whitelist person
  function claimTokens() 
    external
    icoHasEnded
  {
    Participant storage participant = participants[msg.sender];
    require(participant.whitelistStatus == Status.Approved);
    require(participant.qtyTokens != 0);
    uint256 tkns = participant.qtyTokens;
    participant.qtyTokens = 0;
    LogTokensTransferedFrom(owner, msg.sender, tkns);
    cosToken.transferFrom(owner, msg.sender, tkns);
  }

  ///@notice participants can claim their bonus tokens here after the distribute Remaining Tokens function 
  ///has been called claiments will only recieve extra tokens if the tkns calculated is ture they are whitelisted
  ///and purchased within the BONUS TIERS
  function claimBonusTokens()
    public
    icoHasEnded
  {
    Participant storage participant = participants[msg.sender];
    require(tknsCalculated);
    require(participant.whitelistStatus == Status.Approved);
    require(participant.tierPurchased <= BONUS_TIER);
    require(!participant.bonusPaid);
    participant.bonusPaid = true;
    LogBonusRedeemed(msg.sender, tknsPerPerson); 
    cosToken.transferFrom(owner, msg.sender, tknsPerPerson); 
  }

  /// @notice no ethereum will be held in the crowdsale contract
  /// when refunds become available the amount of Ethererum needed will
  /// be manually transfered back to the crowdsale to be refunded
  function claimRefund()
    external
    activeContract
    icoHasEnded
    returns (bool success)
  {
    Participant storage participant = participants[msg.sender];
    require(participant.whitelistStatus == Status.Denied);
    uint256 sendValue = participant.contrAmount;
    participant.contrAmount = 0;
    participant.qtyTokens = 0;
    LogWithdrawal(msg.sender, sendValue);
    msg.sender.transfer(sendValue);
    return true;
  }

  /// @notice no ethereum will be held in the crowdsale contract
  /// when refunds become available the amount of Ethererum needed will
  /// be manually transfered back to the crowdsale to be refunded
  /// @notice only the last person that buys tokens if they deposited enought to buy more 
  /// tokens than what is available will be able to use this function
  function claimRemainingWei()
    external
    activeContract
    icoHasEnded
    returns (bool success)
  {
    Participant storage participant = participants[msg.sender];
    require(participant.whitelistStatus == Status.Approved);
    require(participant.remainingWei != 0);
    uint256 sendValue = participant.remainingWei;
    participant.remainingWei = 0;
    LogWithdrawal(msg.sender, sendValue);
    msg.sender.transfer(sendValue);
    return true;
  }
}