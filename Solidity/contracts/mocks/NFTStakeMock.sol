pragma solidity ^0.6.0;

import "../NFT/NFTStake.sol";
import "../NFT/IERC20.sol";
import "../NFT/ERC1155.sol";


contract NFTStakeMock is NFTStake {

    constructor(address walletAddress)
        public NFTStake(walletAddress) {
    }

    function setRoomTokenAddress(address roomTokenAddress) public {
        roomToken = IERC20(address(roomTokenAddress));
    }

    function setNFTTokenAddress(address NFTTokenAddress) public {
        NFTToken = IERC1155(address(NFTTokenAddress));
    }

    function assignValues() public {
        changeRewardsPerBlockValues(1e18 * 1e18, 1e18 * 1e18, 1e18 * 1e18, 1e18 * 1e18, 1e18 * 1e18, 1036800);
    }

    function assignOrgValues() public {
        uint256 rewardBlockCount = 1036800;

        uint256 totalRewards0 = 24937e18; // total rewards for pool0 (Tier1)
        uint256 totalRewards1 = 30922e18; // total rewards for pool1 (Tier2)
        uint256 totalRewards2 = 36907e18; // total rewards for pool2 (Tier3)
        uint256 totalRewards3 = 44887e18; // total rewards for pool3 (Tier4)
        uint256 totalRewards4 = 62344e18; // total rewards for pool4 (Tier5)

        uint256 p0 = totalRewards0.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        uint256 p1 = totalRewards1.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        uint256 p2 = totalRewards2.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        uint256 p3 = totalRewards3.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        uint256 p4 = totalRewards4.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision

        changeRewardsPerBlockValues(p0, p1, p2, p3, p4, 1036800);
    }
}
