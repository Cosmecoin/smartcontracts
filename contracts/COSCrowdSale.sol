pragma solidity 0.4.18;

import './COSToken.sol';
import './Ownable.sol';
import './SafeMath.sol';

contract COSCrowdSale is Ownable{
  using SafeMath for uint256;

  uint256 constant internal MIN_CONTRIBUTION = 1 ether;
  uint256 constant internal TOKEN_DECIMALS = 10**10;
  uint256 constant internal ETH_DECIMALS = 10**18;
  uint8 constant internal TIER_COUNT = 7;
  uint8 constant internal BONUS_TIER = 3;
  
  uint256 public remainingTokens;
  uint256 public tknsPerPerson;
  uint256 public icoStartTime;
  uint256 public icoEndTime;
  address public teamWallet;
  uint256 public weiRaised;
  uint256 public ethPrice;
  uint256 public decimals;
  uint256 public minLimit;
  address public holdings;
  address public owner;
  uint256 public cap;
  uint8 private tier;
  bool private paused;
  bool public tknsCalculated;

  enum Status {
    New, Approved, Denied
  }

  struct WhitelistedInvestors {
    uint256 contrAmount; //amount in wei
    uint256 qtyTokens;
    uint8 tierPurchased;
    bool bonusPaid;
    Status whitelistStatus;
  }

  mapping(address => WhitelistedInvestors) investors;

  //The Cosmocoin token contract
  COSToken public cosToken; 

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
    require(weiRaised < cap && now < icoEndTime && calculateUnsoldICOTokens() > 0);
    _;
  }

  modifier icoHasEnded() {
    require(weiRaised >= cap || now > icoEndTime || calculateUnsoldICOTokens() == 0);
    _;
  }

  modifier pausedContract(){
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
 
    icoStartTime = now; //pick a block number to start on
    icoEndTime = now + 60 days; //pick a block number to end on
    teamWallet = _teamWallet;
    weiRaised = 0;
    cosToken = COSToken(_cosToken);    
    decimals = 10;
    holdings = _holdings;
    owner = msg.sender;
    cap = 20969 ether;

    saleTier[0].tokensToBeSold = (5000000)*TOKEN_DECIMALS;
    saleTier[1].tokensToBeSold = (7500000)*TOKEN_DECIMALS;

   for(uint8 i=2; i<TIER_COUNT; i++){ 
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
    pausedContract
    isValidPayload
    
    returns (uint8)
  {
    require(investors[msg.sender].whitelistStatus != Status.Denied);
    require(msg.value >= MIN_CONTRIBUTION);

    uint256 price = (ETH_DECIMALS.mul(uint256(16+(4*tier))).div(1000)).div(ethPrice); //wei per token discluding decimals
    uint256 buyTokensRemainingWei;
    uint256 qtyOfTokensRequested = (msg.value.div(price)).mul(TOKEN_DECIMALS);
    uint256 tierRemainingTokens = saleTier[tier].tokensToBeSold.sub(saleTier[tier].tokensSold);
    uint256 remainingWei;
    uint256 amount;

    investors[msg.sender].tierPurchased = tier; 
    
    if (qtyOfTokensRequested >= tierRemainingTokens){
      remainingWei = msg.value.sub((tierRemainingTokens.div(TOKEN_DECIMALS)).mul(price));
      qtyOfTokensRequested = tierRemainingTokens;
      tier++; 

      if (tier < TIER_COUNT){
        buyTokensRemainingWei = (remainingWei.mul(price)).mul(TOKEN_DECIMALS);
        qtyOfTokensRequested += buyTokensRemainingWei;
        saleTier[tier].tokensSold += buyTokensRemainingWei;
        remainingWei = 0;
      } else {
        msg.sender.transfer(remainingWei); 
      }

    } else {
      saleTier[tier].tokensSold += qtyOfTokensRequested;
    }

    amount = msg.value.sub(remainingWei);
    weiRaised += amount;
    holdings.transfer(amount);

    investors[msg.sender].contrAmount += amount;
    investors[msg.sender].tierPurchased = tier;
    if(investors[msg.sender].whitelistStatus == Status.Approved){
      cosToken.transferFrom(owner, msg.sender, qtyOfTokensRequested);
      LogTokensTransferedFrom(owner, msg.sender, qtyOfTokensRequested);     
    } else {
      investors[msg.sender].qtyTokens += qtyOfTokensRequested;
      LogTokensReserved(msg.sender, qtyOfTokensRequested);
    }

    return tier;
  }

  ///@notice I want to get the price of ethereum every time I call the buy tokens function
  ///what has to change in this function to make that happen safely
  ///param ethereum price will exclude decimals
  function getEtherPrice(uint256 _price)
    external
    onlyOwner
    {
      ethPrice = _price;
    }

  /// notice interface for founders to whitelist investors
  ///  addresses array of investors
  ///  tier Number
  ///  status enable or disable
  function whitelistAddresses(address[] _addresses, bool _status) 
    public 
    onlyOwner 
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address investorAddress = _addresses[i];
            if(_status == true){
                approvedWhitelistAddress(investorAddress); 
            } else {
                deniedWhitelistAddress(investorAddress);  
            } 
        }
   }

  /// notice sends requested tokens to the whitelist person
  function approvedWhitelistAddress(address _investorAddress) 
    internal
  {
    require(_investorAddress != 0x0);
    investors[_investorAddress].whitelistStatus = Status.Approved;
    uint256 tkns = investors[_investorAddress].qtyTokens;
    investors[_investorAddress].qtyTokens = 0;
    cosToken.transferFrom(owner, _investorAddress, tkns);
    LogTokensTransferedFrom(owner, msg.sender, tkns);
  }

  /// @notice allows denied buyers the ability to get their Ether back
  function deniedWhitelistAddress(address _investorAddress) 
    internal 
  {
    require(_investorAddress != 0x0);
    investors[_investorAddress].whitelistStatus = Status.Denied;
    investors[_investorAddress].qtyTokens = 0;     
  }

  /// @notice used to move tokens from the later tiers into the earlier tiers
  /// contract must be paused to do the move
  /// param tier from later tier to subtract the tokens from
  /// param tier to add the tokens to
  /// param how many tokens to take
  function moveTokensForSale(uint8 _tierFrom, uint8 _tierTo, uint256 _tokens) 
    public
    onlyOwner
  {
    require(paused = true);
    require(_tierFrom > _tierTo);
    require(_tokens <= ((saleTier[_tierFrom].tokensToBeSold).sub(saleTier[_tierFrom].tokensSold)));

    saleTier[_tierFrom].tokensToBeSold.sub(_tokens);
    saleTier[_tierTo].tokensToBeSold.add(_tokens);
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
    return (investors[msg.sender].whitelistStatus == Status.Approved, investors[msg.sender].tierPurchased < 3);
  }     

  /// @dev freeze unsold tokens for use at a later time
  /// and transfer team, owner and other internally promised tokens
  /// param total number of tokens being transfered to the freeze wallet
  function finalize(uint256 _internalTokens)
    public
    icoHasEnded
    onlyOwner
  {
    cosToken.transferFrom(owner, teamWallet, _internalTokens);
    holdings.transfer(this.balance);   
  }

  /// @notice calculate unsold tokens for transfer to holdings to be used at a later date
  function calculateUnsoldICOTokens()
    internal
    returns (uint256)
  {
    for(uint8 i = 0; i < TIER_COUNT; i++){
      if(saleTier[i].tokensSold < saleTier[i].tokensToBeSold){
        remainingTokens += saleTier[i].tokensToBeSold.sub(saleTier[i].tokensSold);
      }
    }
    return remainingTokens;
  }

  ///param total number of whitelist participants collected from the final count in the database
  ///manually entered here tokens will be then be available for collection by the qualified participants
  function distributeRemainingTokens(uint256 _totalNumWhitelisters)
    public
    icoHasEnded
    onlyOwner
    returns(bool success)
  {
    require(remainingTokens > 20000*TOKEN_DECIMALS);
    uint256 bonusDistribution = remainingTokens.div(2); //split evenly between participants and reserve  
    tknsPerPerson = bonusDistribution.div(_totalNumWhitelisters);
    
    tknsCalculated = true;

    return true;   
  }

  ///@notice participants can claim their bonus tokens here after the distribute Remaining Tokens function 
  ///has been called claiments will only recieve extra tokens if the tkns calculated is ture they are whitelisted
  ///and purchased within the BONUS TIERS
  function claimBonusTokens()
    public
  {
    require(tknsCalculated);
    require(investors[msg.sender].whitelistStatus == Status.Approved);
    require(investors[msg.sender].tierPurchased <= BONUS_TIER);
    require(!investors[msg.sender].bonusPaid);

    investors[msg.sender].bonusPaid = true;
    LogBonusRedeemed(msg.sender, tknsPerPerson); 

    cosToken.transferFrom(owner, msg.sender, tknsPerPerson);

    
  }
}