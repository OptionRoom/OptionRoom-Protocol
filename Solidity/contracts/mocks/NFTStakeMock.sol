pragma solidity ^0.6.0;

import "../NFT/NFTStake.sol";
import "../NFT/IERC20.sol";
import "../NFT/ERC1155.sol";


contract NFTStakeMock is NFTStake {

    function setRoomTokenAddress(address roomTokenAddress) public {
        roomToken = IERC20(address(roomTokenAddress));
    }

    function setNFTTokenAddress(address NFTTokenAddress) public {
        NFTToken = IERC1155(address(NFTTokenAddress));
    }

    function assignValues() public {
        uint256 rewardBlockCount = 1036800;  // 5760 * 30 * 6; six months = 1,036,800 blocks

        _finishBlock = blockNumber().add(rewardBlockCount);

        _rewardPerBlock[0] = 1e18;
        _rewardPerBlock[1] = 1e18;
        _rewardPerBlock[2] = 1e18;
        _rewardPerBlock[3] = 1e18;
        _rewardPerBlock[4] = 1e18;

        _lastUpdateBlock[0] = blockNumber();
        _lastUpdateBlock[1] = blockNumber();
        _lastUpdateBlock[2] = blockNumber();
        _lastUpdateBlock[3] = blockNumber();
        _lastUpdateBlock[4] = blockNumber();
    }
}
