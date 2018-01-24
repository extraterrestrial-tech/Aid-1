var DummyCoin1 = artifacts.require("DummyCoin1");
var DummyCoin2 = artifacts.require("DummyCoin2");
var DummyCoin3 = artifacts.require("DummyCoin3");

module.exports = function(deployer) {
  deployer.deploy(DummyCoin1);
  deployer.deploy(DummyCoin2);
  deployer.deploy(DummyCoin3);
};
