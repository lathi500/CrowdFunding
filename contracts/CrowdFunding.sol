//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Crowdfunding {


    /**
     * @dev emitted on project creation. User can get created projectId.
    */
    event projectCreated(bytes32 projectId, address projectOwner);

    /**
     * @dev emitted when user has successfully provided fund to project
    */
    event fundProvided(uint256 userFundedAmount, address fundProvider);

    /**
     * @dev emitted when project owner has suceessfully claimed fund
     */
    event fundClaimed(uint256 totalClaimedFund, address projectOwner);

    /**
     * emitted when user refunded whith provided fund on project.
     */
    event fundRefunded(uint256 reFundedAmount, address user);

    address public owner;

    struct projectData {
        address projectCreator;
        uint startingTime;
        uint endTime;
        uint fundingGoal;
        uint totalRecievedFund;
    }

    IERC20 myToken;

    mapping(bytes32 => projectData) public _projectData;
    mapping(bytes32 => mapping(address => uint)) public customrFundedAmount;

    /**
     * @param _myToken Platform token address
     */

    constructor(address _myToken) {
        myToken = IERC20(_myToken);
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller Is Not Owner");
        _;
    }

    /**
     * @dev platform owner can start project
     * @param _fundingGoal required fund for project
     * @param _endTime fundraise ending time
     * @return bool project creation status
     */

    function startProject(uint _fundingGoal, uint _endTime)
        external
        isOwner
        returns (bool)
    {
        require(
            _endTime > block.timestamp,
            " End time must be grater than start time"
        );
        require(_fundingGoal > 0, " Must have required goal fund ");

        bytes32 projectId = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                _endTime,
                _fundingGoal
            )
        );

        _projectData[projectId].projectCreator = msg.sender;
        _projectData[projectId].startingTime = block.timestamp;
        _projectData[projectId].endTime = _endTime;
        _projectData[projectId].fundingGoal = _fundingGoal;

        emit projectCreated(projectId, msg.sender); // User can get project Id thorough emited event
        return true;
    }

    /**
     * @dev user can fund on project using projectId.
     * @param projectId  projectId on wich user want to provide fund.
     * @param amounForFund fund amount user want to provide for given project id.
     */

    function fundProject(bytes32 projectId, uint amounForFund) external {
        require(
            _projectData[projectId].endTime > block.timestamp,
            "Time is over for accepting fund on given project"
        );
        require(msg.sender != owner, "Owner can not fund an project");
        require(
            _projectData[projectId].fundingGoal > amounForFund,
            "Over loaded required fund amount"
        );
        require(
            (_projectData[projectId].totalRecievedFund + amounForFund) <=
                _projectData[projectId].fundingGoal &&
                _projectData[projectId].totalRecievedFund <=
                _projectData[projectId].fundingGoal,
            "No more fund required for project"
        );

        myToken.approve(address(this), amounForFund);
        myToken.transferFrom(msg.sender, address(this), amounForFund);

        customrFundedAmount[projectId][msg.sender] = amounForFund;
        _projectData[projectId].totalRecievedFund += amounForFund;

        emit fundProvided(amounForFund, msg.sender);
    }

    /**
     * @dev Project owner can claim fund using project id( Note: project fundraise time must be completed )
     * @param projectId Id of project
     */

    function claimFunds(bytes32 projectId) public isOwner {
        require(
            _projectData[projectId].endTime < block.timestamp,
            "Can not claim befor project ending"
        );
        require(
            _projectData[projectId].fundingGoal ==
                _projectData[projectId].totalRecievedFund,
            "Funding Goal is not reached"
        );

        _projectData[projectId].totalRecievedFund = 0;
        myToken.transfer(
            msg.sender,
            _projectData[projectId].fundingGoal
        );
        emit fundClaimed(_projectData[projectId].fundingGoal, msg.sender);
    }

    /**
     * @dev user can get fund back if funding goal is not full filled.
     * @param projectId Id of project.
     */

    function getRefund(bytes32 projectId) public {
        require(
            _projectData[projectId].totalRecievedFund <
                _projectData[projectId].fundingGoal,
            "funding goal not met"
        ); // funding goal not met
        require(
            block.timestamp >= _projectData[projectId].endTime,
            "project time must be ended"
        ); // in the withdrawal period

        uint256 amount = customrFundedAmount[projectId][msg.sender];

        require(amount > 0, "User does not have staked any amount");

        customrFundedAmount[projectId][msg.sender] = 0;
        _projectData[projectId].totalRecievedFund = 0;
        myToken.transfer(msg.sender, amount);
        emit fundRefunded(amount, msg.sender);
    }
}

