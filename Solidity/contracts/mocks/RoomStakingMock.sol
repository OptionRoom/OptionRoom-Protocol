pragma solidity ^0.5.16;

import "../../contracts/Farming/RoomStaking.sol";

contract RoomStakingMock is RoomStaking {

    constructor(uint256 rewardPerBlock, uint256 rewardBlockCount, address walletAddress)
    public RoomStaking(rewardPerBlock, rewardBlockCount, walletAddress) {
    }

    function setRoomTokenAddress(address roomTokenAddress) public {
        roomToken = IERC20(address(roomTokenAddress));
    }

    function setLpTokenAddress(address roomLPTokenAddress) public {
        roomLPToken = IERC20(address(roomLPTokenAddress));
    }


    function getWalletBalance() external view returns (uint256 walletBalanace) {
        walletBalanace = roomToken.balanceOf(roomTokenRewardsReservoirAddress);
    }

    function getCurrentTime() public view returns (uint256){
        return block.timestamp;
    }
}
