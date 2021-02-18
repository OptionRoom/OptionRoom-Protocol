pragma solidity ^0.6.0;

import "../NFT/ERC1155.sol";


contract NFTTokenMock is ERC1155 {

    constructor () public ERC1155("uri") {
        _mint(msg.sender, 0, 1000, "");
        // minting 100,000,000 token with 18 decimals
        _mint(msg.sender, 1, 1000, "");
        // minting 100,000,000 token with 18 decimals
        _mint(msg.sender, 2, 1000, "");
        // minting 100,000,000 token with 18 decimals
        _mint(msg.sender, 3, 1000, "");
        // minting 100,000,000 token with 18 decimals
        _mint(msg.sender, 4, 1000, "");
        // minting 100,000,000 token with 18 decimals
    }

    function mintForAddress(address roomTokenAddress) public {
        _mint(roomTokenAddress, 0, 1000, "");
        _mint(roomTokenAddress, 1, 1000, "");
        _mint(roomTokenAddress, 2, 1000, "");
        _mint(roomTokenAddress, 3, 1000, "");
    }
}
