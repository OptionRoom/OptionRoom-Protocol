// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155.sol";
import "./IERC20.sol";

// This is OptionNFT
contract RoomNFT is ERC1155 {

    mapping(uint256 => uint256) private _totalStaked;
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

    constructor() public ERC1155("uri"){
        _capital[TIER1] = 50;
        _capital[TIER2] = 40;
        _capital[TIER3] = 30;
        _capital[TIER4] = 20;
        _capital[TIER5] = 8;

        requiredRoomBurned[TIER1] = 500e18;
        requiredRoomBurned[TIER2] = 120e18;
        // + burn 1 tire1
        requiredRoomBurned[TIER3] = 120e18;
        // + burn 1 tire2
        requiredRoomBurned[TIER4] = 120e18;
        // + burn 1 tire3
        requiredRoomBurned[TIER5] = 160e18;
        // + burn 1 tire4
    }

    function burn(address account, uint256 id, uint256 value) internal virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _totalStaked[id] = _totalStaked[id].sub(value);
        _burn(account, id, value);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) internal {
        uint256 newTotalStaked = _totalStaked[id].add(amount);
        require(newTotalStaked <= _capital[id], "total supply exceeds capital");
        _totalStaked[id] = newTotalStaked;

        _mint(account, id, amount, data);
    }

    function totalStaked(uint256 id) public view returns (uint256) {
        return _totalStaked[id];
    }

    function capital(uint256 id) public view returns (uint256) {
        return _capital[id];
    }

    function checkAvailableToMint(uint256 id) public view returns (uint256) {
        return _capital[id].sub(_totalStaked[id]);
    }

    function mintTier(uint256 id) public {
        require(id < 5, "unsupported id");

        if (id > 0) {
            burn(_msgSender(), id.sub(1), 1);
            // burn previous tier
        }

        roomToken.transferFrom(_msgSender(), roomBurnAdd, requiredRoomBurned[id]);
        mint(_msgSender(), id, 1, "");
    }

    function mintStatus(address account, uint256 id) public view returns (bool canMint, string memory reason){
        uint256 availableToMint = checkAvailableToMint(id);
        if (availableToMint == 0) {
            canMint = false;
            reason = "no available";
            return (canMint, reason);
        }

        if (id > 0) {
            if (balanceOf(account, id.sub(1)) == 0) {
                canMint = false;
                reason = "account has no previous tier";
                return (canMint, reason);
            }

            if (!isApprovedForAll(account, address(this))) {
                canMint = false;
                reason = "account did not approve this";
                return (canMint, reason);
            }
        }

        if (roomToken.balanceOf(account) < requiredRoomBurned[id]) {
            canMint = false;
            reason = "account do not have the required ROOM tokens amount";
            return (canMint, reason);
        }

        canMint = true;
    }
}
