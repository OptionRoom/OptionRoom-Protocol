pragma solidity ^0.5.0;

//
interface ICourtStake{

    function lockedStake(uint256 amount, address beneficiar,  uint256 StartReleasingTime, uint256 batchCount, uint256 batchPeriod) external;

}
