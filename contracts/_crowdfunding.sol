// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Campaign {
        address payable creator;
        uint goal;
        uint deadline;
        uint fundsRaised;
        bool completed;
        mapping(address => uint) contributions;
    }

    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;

    event CampaignCreated(uint campaignId, address creator, uint goal, uint deadline);
    event ContributionMade(uint campaignId, address contributor, uint amount);
    event FundsWithdrawn(uint campaignId, address creator, uint amount);

    modifier onlyCreator(uint _campaignId) {
        require(msg.sender == campaigns[_campaignId].creator, "Only the creator can execute this function");
        _;
    }

    modifier campaignActive(uint _campaignId) {
        require(block.timestamp < campaigns[_campaignId].deadline, "Campaign has ended");
        require(!campaigns[_campaignId].completed, "Campaign already completed");
        _;
    }

    modifier campaignEnded(uint _campaignId) {
        require(block.timestamp >= campaigns[_campaignId].deadline, "Campaign is still active");
        _;
    }

    function createCampaign(uint _goal, uint _duration) external {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.creator = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.deadline = block.timestamp + _duration;

        emit CampaignCreated(campaignCount, msg.sender, _goal, newCampaign.deadline);
    }

    function contribute(uint _campaignId) external payable campaignActive(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        campaign.fundsRaised += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    function withdrawFunds(uint _campaignId) external onlyCreator(_campaignId) campaignEnded(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.fundsRaised >= campaign.goal, "Campaign did not reach its goal");

        uint amount = campaign.fundsRaised;
        campaign.fundsRaised = 0;
        campaign.completed = true;

        campaign.creator.transfer(amount);
        emit FundsWithdrawn(_campaignId, msg.sender, amount);
    }

    function getContribution(uint _campaignId, address _contributor) external view returns (uint) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}
