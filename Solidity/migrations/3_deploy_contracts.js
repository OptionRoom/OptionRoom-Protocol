const RoomLock = artifacts.require("RoomLock/RoomLock.sol");

module.exports = function(deployer) {
    deployer.deploy(RoomLock);
};
