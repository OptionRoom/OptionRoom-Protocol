pragma solidity ^0.5.16;

import "../../contracts/ERC20/RoomToken.sol";

contract LimitedERC20DetailedMock is ERC20Detailed {

    constructor () public ERC20Detailed("ERC20DetailedMocked", "ERC20DetailedMock", 18) {
//        _mint(msg.sender,1 ); // minting 100,000,000 token with 18 decimals
    }

    function mint(address account, uint amount) public{
        _mint(account,amount);

    }

}
