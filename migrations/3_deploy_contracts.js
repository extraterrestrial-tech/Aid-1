var DummyCoin = artifacts.require("./DummyCoin.sol");

module.exports = function(deployer) {
  deployer.deploy(DummyCoin);
};
