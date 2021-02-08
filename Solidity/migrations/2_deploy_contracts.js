const safeMath = artifacts.require("lib/SafeMath.sol");
const RoomToken = artifacts.require("ERC20/RoomToken.sol");

module.exports = function(deployer) {
    deployer.deploy(safeMath);
    deployer.deploy(RoomToken);
};
