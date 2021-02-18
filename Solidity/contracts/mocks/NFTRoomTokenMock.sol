pragma solidity ^0.5.16;

import "../ERC20/ERC20Detailed.sol";

contract NFTRoomTokenMock is ERC20Detailed {

    constructor () public ERC20Detailed("RoomToken", "ROOM", 18) {
        _mint(msg.sender,100000000e18 ); // minting 100,000,000 token with 18 decimals
    }
}
