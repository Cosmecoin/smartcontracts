pragma solidity 0.4.18;

import './StandardToken.sol';
import './Ownable.sol';

contract COSToken is StandardToken, Ownable {
  address public crowdsaleContract;
  string public constant symbol = "COS";
  string public constant name = "Cosmocoin";
  uint8 public constant decimals = 10;
  bool public paused;

  
  function COSToken()
    public
  {
    // 333,000,000 total supply of COS tokens
    totalSupply = 333000000 * 10**10;
    paused = true;
                  
												 
	  balances[msg.sender] = totalSupply;
    Transfer(0, owner, totalSupply);

    // making sure the msg.sender and the owner are the same, and that the
		// address of the owner recieved the totalSupply of tokens.
    assert(balances[owner] == totalSupply);                
  }

  ///@notice adds the ability to set the crowdsaleContract by the owner for transfer and transferfrom functions
  function setCrowdsaleContract(address _crowdsaleContract)
  public 
  onlyOwner {
  crowdsaleContract = _crowdsaleContract;
  }

  ///@notice once activated the tokens will be transferable by token holders cannot be reverted
  function activate() 
  public
  onlyOwner {
  paused = false;
  }

  ///@notice doesnt allow transfer until unpaused or crowdsaleContract calls it
  function transfer(address _to, uint256 _value) public returns (bool) {
    require (!paused || msg.sender == crowdsaleContract); 
    return super.transfer(_to, _value);
  }

  ///@notice doesnt allow transferFrom until unpaused or crowdsaleContract calls it
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require (!paused || msg.sender == crowdsaleContract); 
    return super.transferFrom(_from, _to, _value);
  }
}


