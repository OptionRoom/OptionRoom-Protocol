pragma solidity ^0.5.16;

import "../../contracts/Farming/CourtFarming.sol";

contract FarmingTimeSimulation is CourtFarming {
    uint256 public cBlockNumber = block.number;
    constructor() public CourtFarming(1e18, 1000, 15e17, 500, 500) {

    }

    function blockNumber() public view returns (uint256) {
        return cBlockNumber;
    }

    function incrementBlockNumber(uint256 count) public {
        cBlockNumber += count;
    }
}
