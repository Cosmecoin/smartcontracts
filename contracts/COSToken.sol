pragma solidity 0.4.19;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract COSToken is StandardToken, Ownable {
    
    address public crowdsaleContract;
    string public constant symbol = "COSX";
    string public constant name = "Cosmecoin";
    uint8 public constant decimals = 10;
    bool public paused;

  function COSToken()
    public
    {
        totalSupply = 500000000 * 10**10;
        paused = true;
        balances[msg.sender] = totalSupply;
        assert(balances[owner] == totalSupply);                
    }

  ///notice adds the ability to set the crowdsaleContract by the owner for transfer and transferfrom functions
  function setCrowdsaleContract(address _crowdsaleContract)
    public 
    onlyOwner 
    {
        crowdsaleContract = _crowdsaleContract;
    }

  ///notice once activated the tokens will be transferable by token holders cannot be reverted
  function activate() 
    public
    onlyOwner 
    {
        paused = false;
    }
    
  function transfer(address _to, uint256 _value) 
    public 
    returns (bool) 
    {
        require (!paused || msg.sender == crowdsaleContract); //doesnt allow transfer until unpaused or crowdsaleContract calls it
        return super.transfer(_to, _value);
    }

  function transferFrom(address _from, address _to, uint256 _value) 
    public 
    returns (bool) 
    {
        require (!paused || msg.sender == crowdsaleContract); //doesnt allow transferFrom until unpaused or crowdsaleContract calls it
        return super.transferFrom(_from, _to, _value);
    }
}





