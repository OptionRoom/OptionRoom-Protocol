const TeamLock = artifacts.require("RoomLock/TeamRoomLock.sol");

module.exports = function(deployer) {
    deployer.deploy(TeamLock);
};
