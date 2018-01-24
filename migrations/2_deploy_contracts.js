var Aid1 = artifacts.require("Aid1");
var Aid1_Testing = artifacts.require("Aid1_Testing");

module.exports = function(deployer) {
  deployer.deploy(Aid1);
  deployer.deploy(Aid1_Testing);
};
