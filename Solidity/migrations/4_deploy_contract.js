const RoomLockSimulator = artifacts.require("Simulation/RoomLockSimulator.sol");
const SafeERC20 = artifacts.require("openzeppelin/contracts/token/ERC20/SafeERC20.sol");


module.exports = function(deployer) {
    deployer.deploy(SafeERC20);
    deployer.deploy(RoomLockSimulator);
};
