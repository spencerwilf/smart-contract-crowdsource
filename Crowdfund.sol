// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Crowdfund {

    error Crowdfund__DateOutOfRange();
    error Crowdfund__ContributionTooSmall();

    mapping(address => uint) public contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minimumContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;
    uint public numRequests;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;

    event Contribution(address _sender, uint _value);
    event CreateRequest(string _description, address _recipient, uint _value);
    event MakePayment(address _recipient, uint _value);

    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        admin = msg.sender;
    }

    function contribute() public payable {
        if (block.timestamp > deadline) {
            revert Crowdfund__DateOutOfRange();
        }
        if (msg.value < minimumContribution) {
            revert Crowdfund__ContributionTooSmall();
        }
        if (contributors[msg.sender] == 0) {
            numberOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;

        emit Contribution(msg.sender, msg.value);
    }

    receive() external payable {
        contribute();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);
        contributors[msg.sender] = 0;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only the admin can call this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numRequests];
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.numberOfVoters = 0;
        emit CreateRequest(_description, _recipient, _value);
    } 

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false);
        thisRequest.voters[msg.sender] = true;
        thisRequest.numberOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyAdmin {
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false);
        require(thisRequest.numberOfVoters > numberOfContributors / 2);
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        emit MakePayment(thisRequest.recipient, thisRequest.value);
    }
}