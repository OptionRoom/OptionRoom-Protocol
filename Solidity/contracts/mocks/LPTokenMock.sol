pragma solidity ^0.5.16;

import "../../contracts/ERC20/RoomToken.sol";

contract LPTokenMock is ERC20Detailed {

    constructor () public ERC20Detailed("DummyLP", "DummyLP", 18) {
        _mint(msg.sender,10000000e18 ); // minting 100,000,000 token with 18 decimals
    }

}
