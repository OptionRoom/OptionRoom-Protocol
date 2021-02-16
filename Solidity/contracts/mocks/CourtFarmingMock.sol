pragma solidity ^0.5.0;

import "../Farming/CourtFarming.sol";

contract CourtFarmingMock is CourtFarming {

    constructor(uint256 rewardPerBlock, uint256 rewardBlockCount,
        uint256 incvRewardPerBlock, uint256 incvRewardBlockCount,
        uint256 incvLockTime) public CourtFarming(rewardPerBlock, rewardBlockCount, incvRewardPerBlock,
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
