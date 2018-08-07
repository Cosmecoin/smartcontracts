pragma solidity 0.4.24;

import './Token.sol';

contract ClinicPatientVendorHub{
	
	address private owner; //owner should be basic account

	Token public token;
	Patient public patient;
	Clinic public clinic;

	Clinic[] public clinicList;
	Patient[] public patientList;
	Vendor[] public vendor;

	modifier restricted() { 
		require (msg.sender == owner); 
		_; 
	}
	

	function transferTokens(address recipient, uint amount)
		public
		restricted
		returns(bool success)
	{
		return(token.transfer(recipient, amount));
	}

	function transferEth(address recipient, uint amount)
		public
		payable
		restricted
		returns(bool success)
	{
		require(address(this).balance >= amount);
		return(recipient.transfer(amount));
	}

	function addClinic(address owner, bytes32 clinicName)
		public
		restricted
	{
		Clinic newClinic = new Clinic(owner, name);
		clinicList.push(newClinic);
	}
	function addPatient(){}
	function addVendor(){}
	function removeVendor(){}
	function removePatient(){}
	function removeClinic(){}
}

contract Patient{
	address private owner;

	struct Procedure{
		string procedureType; //doc will have a dropdown menu
		bytes32 productType;  //go in with QR code
		bytes32 productAmount;//manual enter for botox, filler etc, blank for other products
		bytes32 productSize;  //QR code entered
		address productVendor;
		bytes32 demographicIPFSAddress; //address loads during completion of the procedure, sends app data into IPFS
		bool infoSharePermission;
	}

	mapping(bytes32 => Procedure) public procedures;
	mapping(address => bool) public permission;
	
	function makePayment(){}
	function givePermission()internal{}//each procedure gets permissioned
	function removePermission(address ){}
	function accessEdit(){}//practitioner

}

//bytes32 was used incase I want to hash anything
contract Clinic{
	address private owner; //use get function to display owner address

	struct Practitioner{
		bytes32 firstName;
		bytes32 lastName;
		bytes32 licenseNumber;
		bytes32 email;
	}

	address[] public patients;
	Practitioner[] public practitioner;
	function addPatients(){} //scan QR code on patients screen
	function addPractitioner(){} //this boils down to tablet or iPad
	function removePatients(){}
	function makePayment(){}
	function rating(){}
	function scanProduct(address vendor, bytes32 productData){}
}

contract Vendor{

	address private owner;
	mapping(address => bool) public admin;	
	mapping(address => bool) public authorized;

	event LogSetAdmin(address indexed newAdmin, address indexed adminSetBy, uint whenWasSet);
	event LogSetAutorized(address indexed newAuth, address indexed authSetBy, uint dateSet);

	modifier onlyAdmin() { 
		require (admin[msg.sender]); 
		_; 
	}

	modifier authorizedOnly() {
		require (authorized[msg.sender]); 
		_; 
	}


	struct Product{
		uint expiryDate;		//blank if not applicable ie breast implant
		uint mfgDate;
		uint procedureDate;
		string description;
		bytes32 serialNumber;
		uint amountMfg; 		//if volumetric in CC? MicroLitres? etc
		uint amountUsed;
		address recipient; 		//if permissioned
		bool installedAdministered;
		bool removed;
		uint removalDate;
	}

	Product[] public Products;

	function addAdmin(address administrator)
		public
		returns(bool adminSet)
	{
		require(msg.sender == owner);
		admin[administrator] = true;
		emit LogSetAdmin(administrator, owner, now);
		return(admin[administrator]);
	}

	function addAuthorized(address newAuth)
		public
		onlyAdmin
		returns(bool authSet)
	{
		authorized[newAuth] = true;
		emit LogSetAutorized(newAuth, msg.sender, now);
		return(admin[newAuth]);	
	}

	function patientData(){}
	function practitionerData(){}
	function productData(){}
	function payPatient()internal{}
	function payClinic()internal{}

	function addProduct(
		uint expiryDate, 
		uint mfgDate,
		string description,
		bytes32 serialNumber,
		uint amountMfg)
		public
		authorizedOnly //create a list of authorized people that can call this function
	{

	}

	function removeProduct(){}

}

