pragma solidity ^0.6.0;

import "../NFT/RoomNFT.sol";
import "../NFT/IERC20.sol";


contract OptionNFTMock is RoomNFT {
    function setRoomTokenAddress(address roomTokenAddress) public {
        roomToken = IERC20(address(roomTokenAddress));
    }
}
