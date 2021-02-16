// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155.sol";
import "./IERC20.sol";

// This is OptionNFT
contract RoomNFT is ERC1155 {

    mapping(uint256 => uint256) private _totalSupplay;
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

        _totalSupplay[id] = _totalSupplay[id].sub(value);
        _burn(account, id, value);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) internal {

        uint256 newTotalSupply = _totalSupplay[id].add(amount);
        require(newTotalSupply <= _capital[id], "total supply exceeds capital");
        _totalSupplay[id] = newTotalSupply;

        _mint(account, id, amount, data);
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupplay[id];
    }

    function capital(uint256 id) public view returns (uint256) {
        return _capital[id];
    }

    function CheckAvilableToMint(uint256 id) public view returns (uint256) {
        return _capital[id].sub(_totalSupplay[id]);
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


    function CheckCanMint(address account, uint256 id) public view returns (bool canMint, string memory reason){
        uint256 avilableToMint = CheckAvilableToMint(id);
        if (avilableToMint == 0) {
            canMint = false;
            reason = "no available kkkk";
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
                reason = "account dosnot approve this";
                return (canMint, reason);
            }
        }

        if (roomToken.balanceOf(account) < requiredRoomBurned[id]) {
            canMint = false;
            reason = "account has not the required ROOM amount";
            return (canMint, reason);
        }

        canMint = true;

    }
}
