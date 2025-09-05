// InsurancePool insurancePool = new InsurancePool(IERC20(token), msg.sender);
import { ethers } from "hardhat";

// Mock USDC for testing
import { MockUSDC } from "../../typechain-types/contracts/mocks/MockUSDC";
import { InsurancePool } from "../../typechain-types/contracts/src/core/InsurancePool";
import { TestVault } from "../../typechain-types/contracts/src/core/TestVault";
import { TestController } from "../../typechain-types/contracts/src/core/TestController";

let controller: TestController;

async function main() {
  const [deployer] = await ethers.getSigners();

  // Assume token is already deployed (e.g. USDC mock)
  const Token = await ethers.getContractFactory("MockUSDC");
  const token = await Token.deploy();
  await token.deployed();

  // Deploy InsurancePool
  const InsurancePool = await ethers.getContractFactory("InsurancePool");
  const insurancePool = await InsurancePool.deploy(token.address, deployer.address);
  await insurancePool.deployed();
  console.log("InsurancePool deployed to:", insurancePool.address);

  // Deploy Vault
  const TestVault = await ethers.getContractFactory("TestVault");
  const vault = await TestVault.deploy(token.address, controller.address);
  await vault.deployed();
  console.log("Vault deployed to:", vault.address);

  // Link Vault to InsurancePool
  await vault.setInsurancePool(insurancePool.address);
}
