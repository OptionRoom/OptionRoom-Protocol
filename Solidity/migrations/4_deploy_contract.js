const RoomLockSimulator = artifacts.require("Simulation/RoomLockSimulator.sol");

module.exports = function(deployer) {
    deployer.deploy(RoomLockSimulator);
};
