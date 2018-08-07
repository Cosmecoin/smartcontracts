pragma solidity 0.4.19;

import './COSToken.sol';
import './CosPractitioner.sol';
import './CosPlatform.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';


///possibl use case for civil or uport or other id maybe medical id smart contract 
contract CosCustomer is Ownable{
	using SafeMath for uint256;

	address public constant COSTOKEN = '12345ADDRESS';

	string public constant patientFirstName;
	string public constant patientLastName;
	uint256 public balanceOfCOS;//pay for the service and or product
	uint256 public balanceOfEth;//pay for the gas
	bytes32 internal constant customerID;//hash of IPFS address for AML 
	

	struct treatment{
		uint256 cost;
		uint256 dateAndTime; //in miliseconds
		bool treatementPaid;
		bool treatementComplete;
		bytes32[] customerTreatmentRecords;//provide permission to unlock IPFS locations might remove, keep out of BC
	}

	//Dr address/date and time hashed
	mapping (bytes32 => treatment) treatments;
	

	function CosCustomer(string _patientFirstName, string _patientLastName)
		public
		{
			owner = msg.sender;
			patientFirstName = _patientFirstName;;
			patientLastName = _patientLastName;
			cosToken = COSToken(COSTOKEN);
		}

	function approveDocAccess()
		public
		onlyOwner
		{
			//give doctor access to treatement specific file storage
		}

	function payService(address doctorAddress, uint256 serviceCost, bytes32 treatementHash)
		public
		onlyOwner
		{
			CosPractitioner memory cosPractitioner = CosPractitioner(doctorAddress);
			require(doctorAddress == //treatement dr address use keccek256 compare);
			cosToken.transfer(doctorAddress, serviceCost); //signed transaction 
		}

	function leaveRating(address practitioner, uint256 zeroToFive)
	 	public
	 	onlyPatients
	 	{
	 		//rating of zero to five
	 	}
	

