//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Crowdfunding {

    IERC20 myToken;

    event projectCreated( bytes32 projectId );
     
    address public owner;
   
     struct projectData
     {
        address projectCreator;
        uint startingTime;
        uint endTime;
        uint fundingGoal;
        uint totalRecievedFund;
     }

     mapping ( bytes32 => projectData ) public _projectData;
     mapping ( bytes32 => mapping(address => uint)) public customrFundedAmount;

    constructor(address _myToken) 
    {
        myToken = IERC20(_myToken);
        owner = msg.sender;
    }

    modifier isOwner() {
           require(msg.sender == owner,"Caller Is Not Owner");
           _; 
    }

    function startProject( uint _fundingGoal, uint _endTime  ) external isOwner returns(bool) 
    {
            require( _endTime > block.timestamp," End time must be grater than start time");
            require( _fundingGoal > 0," Must have required fund ");

            bytes32 projectId = keccak256( abi.encodePacked(
                msg.sender,
                block.timestamp,
                _endTime,
                _fundingGoal
            ));

            _projectData[projectId].projectCreator = msg.sender;
            _projectData[projectId].startingTime = block.timestamp;
            _projectData[projectId].endTime = _endTime;
            _projectData[projectId].fundingGoal = _fundingGoal;

            emit projectCreated(projectId);
            return true;
    }        
    

    function fundProject( bytes32 projectId, uint amounForFund ) external
    {
         require(_projectData[projectId].endTime > block.timestamp,"Time is over for accepting fund on given project");
         require( msg.sender != owner, "Owner can not fund an project");
         require(_projectData[projectId].fundingGoal > amounForFund,"Over loaded required fund amount" );
         require((_projectData[projectId].totalRecievedFund + amounForFund) <= _projectData[projectId].fundingGoal
         && _projectData[projectId].totalRecievedFund <= _projectData[projectId].fundingGoal,
         "No more fund required for project");

        myToken.approve(address(this), amounForFund);
        myToken.transferFrom(msg.sender, address(this), amounForFund);

        customrFundedAmount[projectId][msg.sender] = amounForFund;
        _projectData[projectId].totalRecievedFund += amounForFund;
    }
    
    function claimFunds( bytes32 projectId ) public isOwner {
        require(_projectData[projectId].endTime < block.timestamp,"Can not claim befor project ending");
        require(_projectData[projectId].fundingGoal == _projectData[projectId].totalRecievedFund,"Funding Goal is not reached");

        myToken.approve(msg.sender,_projectData[projectId].fundingGoal);
        myToken.transferFrom(address(this), msg.sender, _projectData[projectId].fundingGoal);
    }

    function getRefund(bytes32 projectId) public {
        require(_projectData[projectId].totalRecievedFund <  _projectData[projectId].fundingGoal,"funding goal not met");  // funding goal not met
        require(block.timestamp >= _projectData[projectId].endTime,"project time must be ended");               // in the withdrawal period

        uint256 amount = customrFundedAmount[projectId][msg.sender];
        myToken.approve(msg.sender,amount);
        myToken.transferFrom(address(this), msg.sender, amount);
        customrFundedAmount[projectId][msg.sender] = 0;
    }
}