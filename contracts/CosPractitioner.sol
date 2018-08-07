pragma solidity 0.4.19;

import './COSToken.sol';
import './CosCustomer.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract CosPractitionerWallet is Ownable{
	using SafeMath for uint256;

	address public constant COSTOKEN = '12345ADDRESS';
	address public constant COSME_ADDRESS = '2235address';

	string public practitionerFirstName;
	string public practitionerLastName;
	uint256 public rating; //number will be between 50 and 0 platform will have to convert to decimal
	uint256 public balanceOfCOS;
	
	COSToken public cosToken; = COSToken(customerID);
	
	struct Review{
		address customerID;//questionable if this makes sense or not
		uint256 rating;
		bytes32 remoteStoredComments;//IPFS location
	}
	
	Review[] public reviews;

	modifier onlyPatients(uint _time) { 
		if (now >= _time) throw; 
		_; 
	}
	

	function CosPractitionerWallet(string _practitionerFirstName, string _practitionerLastName)
		public
		{
			owner = msg.sender;
			practitionerFirstName = _practitionerFirstName;
			practitionerLastName = _practitionerLastName;
			cosToken = COSToken(COSTOKEN);
		}

	function getBalance()
		public
		returns (uint256)
		{
			balanceOfCOS = cosToken.balanceOf(msg.sender);
		}

	/*@notice similar to current payment transaction method practitioner requests payment
	* customer offers method of payment. In this case its with tokens. 
	*@param paymentAmount in tokens, front end will account for fiat pricing etc
	*@param customerID is the customer address gotten from QR code, Dr will have tablet or other to read
	*/
	function paymentServices(address customerID)
		public
		onlyOwner
		{
			CosCustomer memory cosCustomer = CosCustomer(customerID); //short term instance for single transaction
			cosCustomer.paymentWithdraw();
			//convert from fiat to cos coins
			//insert amount into escrow payment 
		}

	//tokens only from customer wallet
	function servicePayment(uint256 serviceCost, bytes32 treatementHash) 
		external
		{
			require(serviceCost != 0);
			require(msg.sender == /*customer protect against false reviews*/ );
			cosToken.transfer(COSME_ADDRESS, sendValue);
			CosCustomer memory cosCustomer = CosCustomer(customerID); //short term instance for single transaction
			cosCustomer.treatements[treatementHash].treatementPaid = true;
			//takes payment from patients
			//sends payment to platform and Dr account
		}

	 function withdrawTokens()
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

	 function setRecords(bytes32 ipfsAddress, address patient)
		public
		onlyPractitioner
		{
			//only the practitioner that is working with the specific patient 

		}	
}