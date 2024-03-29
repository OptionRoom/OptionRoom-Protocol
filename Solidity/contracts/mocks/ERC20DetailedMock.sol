pragma solidity ^0.5.16;

import "../../contracts/ERC20/RoomToken.sol";
import "../Farming/ICourtStake.sol";

contract ERC20DetailedMock is ERC20Detailed, ICourtStake {

    constructor () public ERC20Detailed("ERC20DetailedMocked", "ERC20DetailedMock", 18) {
        _mint(msg.sender,1e18 ); // minting 100,000,000 token with 18 decimals
    }

    function mint(address account, uint amount) public{
        _mint(account,amount);

    }

    function lockedStake(uint256 amount, address beneficiar,
        uint256 StartReleasingTime, uint256 batchCount, uint256 batchPeriod) external {
//    lockedStake
    }

}
