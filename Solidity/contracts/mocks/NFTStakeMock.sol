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
        uint256 rewardBlockCount = 1036800;  // 5760 * 30 * 6; six months = 1,036,800 blocks

        _rewardPerBlock[0] = 1e18 * 1e18;
        _rewardPerBlock[1] = 1e18 * 1e18;
        _rewardPerBlock[2] = 1e18 * 1e18;
        _rewardPerBlock[3] = 1e18 * 1e18;
        _rewardPerBlock[4] = 1e18 * 1e18;

        _finishBlock = blockNumber().add(rewardBlockCount);

        _lastUpdateBlock[0] = blockNumber();
        _lastUpdateBlock[1] = blockNumber();
        _lastUpdateBlock[2] = blockNumber();
        _lastUpdateBlock[3] = blockNumber();
        _lastUpdateBlock[4] = blockNumber();
    }

    function assignOrgValues() public {
        _rewardPerBlock[0] = 0;

        uint256 rewardBlockCount = 1036800;  // 5760 * 30 * 6; six months = 1,036,800 blocks

        uint256 totalRewards0 = 24937e18; // total rewards for pool0 (Tier1)
        uint256 totalRewards1 = 30922e18; // total rewards for pool1 (Tier2)
        uint256 totalRewards2 = 36907e18; // total rewards for pool2 (Tier3)
        uint256 totalRewards3 = 44887e18; // total rewards for pool3 (Tier4)
        uint256 totalRewards4 = 62344e18; // total rewards for pool4 (Tier5)

        _finishBlock = blockNumber().add(rewardBlockCount);

        _rewardPerBlock[0] = totalRewards0.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        _rewardPerBlock[1] = totalRewards1.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        _rewardPerBlock[2] = totalRewards2.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        _rewardPerBlock[3] = totalRewards3.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision
        _rewardPerBlock[4] = totalRewards4.mul(1e18).div(rewardBlockCount); // mul(1e18) for math precision

        _lastUpdateBlock[0] = blockNumber();
        _lastUpdateBlock[1] = blockNumber();
        _lastUpdateBlock[2] = blockNumber();
        _lastUpdateBlock[3] = blockNumber();
        _lastUpdateBlock[4] = blockNumber();
    }

    function getRewardValueForPool1() public view returns (uint256) {
        return _rewardPerBlock[0];
    }
}
