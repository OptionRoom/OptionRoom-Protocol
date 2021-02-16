const ICourtStake = artifacts.require("Farming/ICourtStake.sol");
const CourtFarming = artifacts.require("Farming/CourtFarming.sol");

module.exports = function(deployer) {
    deployer.deploy(ICourtStake);
    deployer.deploy(CourtFarming);
};
