pragma solidity 0.4.18;

import './COSToken.sol';
import './Ownable.sol';
import './SafeMath.sol';

contract COSTeamWallet is Ownable{
  using SafeMath for uint256;

  uint256 constant public FREEZE_TIME = 425 days; //accounts for ICO days
  
  COSToken public cosToken;
  uint256 public startTime;
  uint256 public totalWithdrawn;

  mapping (address => uint256) teamMember;
  
  event LogWithdrawal(address _teamMember, uint256 _tokenAmount);
  

  modifier withdrawalAvailable() { 
    require(now >= startTime.add(FREEZE_TIME)); 
    _; 
  }
  
  function COSTeamWallet(address _cosToken)
    public
  {  
    require(_cosToken != 0x0);
    startTime = now;
    cosToken = COSToken(_cosToken);
    owner = msg.sender;
  }

  function addTeamMember(address _teamMember, uint256 _tokenAmount)
    public
    onlyOwner
    returns(bool success)
  {
    teamMember[_teamMember] = _tokenAmount;
    return true;
  }

  function transferTeamTokens()
    public
    withdrawalAvailable
    returns (bool success)
  {
    uint256 sendValue = teamMember[msg.sender];
    teamMember[msg.sender] = 0;
    cosToken.transfer(msg.sender, sendValue);
    LogWithdrawal(msg.sender, sendValue);
    return true;
  }

}
