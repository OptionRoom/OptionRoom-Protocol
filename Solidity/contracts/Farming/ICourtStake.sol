pragma solidity ^0.5.0;

//
interface ICourtStake{

    function lockedStake(uint256 amount, uint256 lockTime, address beneficiary) external;

}
