const MT = artifacts.require("MyToken");
const VT = artifacts.require("VestingContract");

module.exports = function (deployer) {
  deployer.deploy(MT);
  deployer.deploy(VT);
};
