pragma solidity 0.4.19;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract contractSupport{

  /**
  * @dev total number of tokens in the contract
  */
  function balanceOfCOS() public view returns (uint256) {
    return balanceOfCOS;
  }

  function transferTokens()
    public
    onlyOwner
    returns (bool success)
  {
    //uint256 sendValue = teamMember[msg.sender];
    //teamMember[msg.sender] = 0;
    cosToken.transfer(msg.sender, sendValue);
    LogWithdrawal(msg.sender, sendValue);
    return true;
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
}