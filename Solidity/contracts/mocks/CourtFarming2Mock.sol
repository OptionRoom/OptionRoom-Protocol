pragma solidity ^0.5.0;

import "../Farming/CourtFarming2.sol";

contract CourtFarming2Mock is CourtFarming {


//    // TODO: fill this info Those are the on the contract deployed.
//    uint256 totalRewards  = 45000e18;
//    uint256 rewardsPeriodInDays = 450;
//    uint256 incvTotalRewards = 18000e18;
//    uint256 incvRewardsPeriodInDays = 60;
//incvLockTime = 1640995200; // 01/01/2022

//    uint256 totalRewards = (5760 * 450) * 1e18;
//    uint256 rewardsPeriodInDays = 1 * 450;
//    uint256 incvTotalRewards = (5760 * 450) * 1e18;
    uint256 incvTotalRewards = (1 * 1e18) ;
    uint256  incvRewardsPeriodInDays = 1 * 450;
    uint256 incvLockTimeAssigned = 1640995200; // 01/01/2022

//incvTotalRewards, uint256 incvRewardsPeriodInDays
    constructor() public CourtFarming(incvTotalRewards, incvRewardsPeriodInDays) {
        // Taken from the testing deployed
        incvStartReleasingTime = 1640995200; // 01/01/2022 // check https://www.epochconverter.com/ for timestamp
        incvBatchPeriod = 1 days;
        incvBatchCount = 1;
    }

    function changeToContractAttributes() public {
        changeStakeParameters(18000e18, 60, 1640995200);
    }

    function increaseAndChangeValues() public {
        changeStakeParameters(2 * 1e18, 1 days, 1640995200);
    }

    function setLPToken(address stakingAddress) public {
        stakedToken = IERC20(address(stakingAddress));
    }

    function setStakingToken(address courtStakeAdd) public {
        courtToken = IMERC20(address(courtStakeAdd));
    }

    function getCurrentTime() public view returns (uint256){
        return block.timestamp;
    }

    function getIncReleaseTime() public view returns (uint256) {
        return incvStartReleasingTime;
    }
}
