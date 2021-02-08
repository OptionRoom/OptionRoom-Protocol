pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/RoomLock/TeamRoomLock.sol";

contract TestTeamLockContracts {

    TeamRoomLock lockContract = new TeamRoomLock();

    function testSeedLockValuesAfterDeploy() public {
        string memory name;
        uint256 totalLocked;
        uint256 startReleasingTime;
        uint256 batchCount;
        uint256 batchPeriodInDays;
        (name, totalLocked, startReleasingTime, batchCount, batchPeriodInDays) = lockContract.getPoolInfo(0);

        Assert.equal(name, "Team Lock", "totalLocked");
        Assert.equal(totalLocked, 10000000e18, "totalLocked");
        Assert.equal(startReleasingTime, 1640995200, "startReleasingTime");
        Assert.equal(batchCount, 4, "batchCount");
        Assert.equal(batchPeriodInDays, 90, "batchPeriodInDays");
    }
}
