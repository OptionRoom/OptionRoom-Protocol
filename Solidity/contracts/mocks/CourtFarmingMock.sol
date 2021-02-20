pragma solidity ^0.5.0;

import "../Farming/CourtFarming.sol";

contract CourtFarmingMock is CourtFarming {

    uint256 constant rewardPerBlock =  1e18;
    uint256 constant rewardBlockCount = 1000;
    uint256 constant incvRewardPerBlock = 1e18 * 1e18 * 15;
    uint256 constant incvRewardBlockCount = 500;
    uint256 constant incvLockTime = 500;

    constructor() public CourtFarming(rewardPerBlock, rewardBlockCount, incvRewardPerBlock,
        incvRewardBlockCount, incvLockTime) {
    }

    function setLPToken(address courtStakeAdd) public {
        lpToken = IERC20(address(courtStakeAdd));
    }

    function setStakingToken(address courtStakeAdd) public {
        courtToken = IMERC20(address(courtStakeAdd));
    }

    function getCurrentTime() public view returns (uint256){
        return block.timestamp;
    }
}
