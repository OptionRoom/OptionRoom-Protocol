// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155.sol";
import "./IERC20.sol";

// This is OptionNFT
contract RoomNFT is ERC1155 {

    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => uint256) private _capital;
    mapping(uint256 => uint256) public requiredRoomBurned;

    uint256 constant TIER1 = 0;
    uint256 constant TIER2 = 1;
    uint256 constant TIER3 = 2;
    uint256 constant TIER4 = 3;
    uint256 constant TIER5 = 4;

    //TODO: ROOM: 0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64
    //IERC20  roomToken = IERC20(0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64);
    IERC20  roomToken = IERC20(0xdDF0667c0694d1AEbED930E30ea06b69BB0D868E);

    address constant roomBurnAdd = address(0x000000000000000000000000000000000000dEaD);

    event TierMinted(bool status, uint256 amount);

    constructor() public ERC1155("uri"){
        _capital[TIER1] = 50;
        _capital[TIER2] = 40;
        _capital[TIER3] = 30;
        _capital[TIER4] = 20;
        _capital[TIER5] = 8;

        requiredRoomBurned[TIER1] = 500e18;
        requiredRoomBurned[TIER2] = 120e18; // + burn 1 tier1
        requiredRoomBurned[TIER3] = 120e18; // + burn 1 tier2
        requiredRoomBurned[TIER4] = 160e18; // + burn 1 tier3
        requiredRoomBurned[TIER5] = 350e18; // + burn 1 tier4
    }

    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _totalSupply[id] = _totalSupply[id].sub(value);
        _burn(account, id, value);
    }

    function mintTier(uint256 id) public returns(bool){
        require(id < 5, "unsupported id");
        require(balanceOf(_msgSender(), id) == 0, "account can not mint while holding nft");

        uint256 newTotalSupply = _totalSupply[id].add(1);
        if(newTotalSupply > _capital[id]){
            emit TierMinted(false,id);
            return false;
        }

        _totalSupply[id] = newTotalSupply;

        if (id > 0) {
            // burn previous tier
            require(balanceOf(_msgSender(), id - 1 ) > 0, "You should have previous tier");
            burn(_msgSender(), id.sub(1), 1);
        }

        roomToken.transferFrom(_msgSender(), roomBurnAdd, requiredRoomBurned[id]);

        _mint(_msgSender(), id, 1, "");
        emit TierMinted(true, id);
        return true;
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    function capital(uint256 id) public view returns (uint256) {
        return _capital[id];
    }

    function checkAvailableToMint(uint256 id) public view returns (uint256) {
        return _capital[id].sub(_totalSupply[id]);
    }
}
