pragma solidity ^0.5.0;

import "../Farming/CourtFarming.sol";

contract CourtFarmingMock is CourtFarming {


//    // TODO: fill this info Those are the on the contract deployed.
//    uint256 totalRewards  = 45000e18;
//    uint256 rewardsPeriodInDays = 450;
//    uint256 incvTotalRewards = 18000e18;
//    uint256 incvRewardsPeriodInDays = 60;
//incvLockTime = 1640995200; // 01/01/2022

    uint256 totalRewards = (5760 * 450) * 1e18;
    uint256 rewardsPeriodInDays = 1 * 450;
    uint256 incvTotalRewards = (5760 * 450) * 1e18;
    uint256  incvRewardsPeriodInDays = 1 * 450;
    uint256 incvLockTimeAssigned = 1640995200; // 01/01/2022

    constructor() public CourtFarming(totalRewards, rewardsPeriodInDays,
        incvTotalRewards, incvRewardsPeriodInDays) {
        incvLockTime = incvLockTimeAssigned;
    }

    function changeToContractAttributes() public {
        changeStakeParameters(45000e18, 450, 18000e18, 60, 1640995200);
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
}
