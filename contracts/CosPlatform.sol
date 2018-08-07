pragma solidity 0.4.19;

import './COSToken.sol';
import './CosPractitioner.sol';
import './CosCustomer.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract CosPlatform is Ownable{
	using SafeMath for uint256;

/*store the list of clients and clinics in the database, address only, no private keys Data Protection Act issues*/

	function CosPlatform()
		public
		{
			owner = msg.sender;
		}

	function newPractitioner()
		public
		return (address)
		{
			CosPractitioner newPractitiioner = new CosPractitioner(/*use address of the basic wallet? or do I pass variables here for instanciation?*/); 
			clinics.push(unnamedClinic.address); 
			//also goes into database	

		function createCampaign(uint campaignDuration, uint campaignGoal)
        public
        returns(address campaignContract)
    {
        Campaign trustedCampaign = new Campaign(msg.sender, campaignDuration, campaignGoal);
        campaigns.push(trustedCampaign);
        campaignExists[trustedCampaign] = true;
        LogNewCampaign(msg.sender, trustedCampaign, campaignDuration, campaignGoal);
        return trustedCampaign;
    }
		}
	function newCustomer()
		public
		{
			//creates new instance of patients sol
			//push customer/patient address into array for tracking 
			//database etc holds database
		}

	function adminControls()
		public
		onlyOwner
		{
			//not sure what controls are needed...
		}

}
