pragma solidity ^0.5.16;

import "../RoomLock/TokenVestingPools.sol";
import "../ERC20/RoomToken.sol";

contract RoomLockSimulator is TokenVestingPools {

    constructor () public TokenVestingPools(0x088441249d9D92e9592AcbfbB6DD1Ce9DF01723A){
    }

    function setLockedToken(address _token) public{
        lockedToken = IERC20(_token);
    }

    // Simulated room lock for testing.
    function setLockedTokenExternal(address _tokenAddress) public {
        setLockedToken(_tokenAddress);
    }

    // Simulated room lock for testing.
    function addSimulatedBeneficiary(
        address _account, uint256 _lockedTokensAmount,
        string memory _poolName, uint256 _startReleasingTime, uint256 _claimingCount,  uint256 _claimingInterval) public returns(uint256 operationStatus) {
        operationStatus = 0;
        uint8 poolCreated = _addVestingPool(_poolName, _startReleasingTime, _claimingCount, _claimingInterval);

        _addBeneficiary(poolCreated, _account,_lockedTokensAmount);

        return operationStatus;
    }
}
