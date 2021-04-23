const Stakingpool = artifacts.require("Stakingpool");

module.exports = function (deployer) {
  deployer.deploy(Stakingpool);
};


