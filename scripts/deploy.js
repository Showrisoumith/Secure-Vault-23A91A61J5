const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("----------------------------------------------------");
  console.log("Starting Deployment...");
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Network:", hre.network.name);
  console.log("----------------------------------------------------");

  // Step 1: Deploy AuthorizationManager
  // We use the deployer's address as the initial 'trustedSigner' for testing
  const AuthorizationManager = await hre.ethers.getContractFactory("AuthorizationManager");
  const authManager = await AuthorizationManager.deploy(deployer.address);
  await authManager.waitForDeployment();
  const authManagerAddress = await authManager.getAddress();

  console.log("✅ AuthorizationManager deployed to:", authManagerAddress);

  // Step 2: Deploy SecureVault
  // We pass the address of the AuthorizationManager to the Vault's constructor
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const vault = await SecureVault.deploy(authManagerAddress);
  await vault.waitForDeployment();
  const vaultAddress = await vault.getAddress();

  console.log("✅ SecureVault deployed to:", vaultAddress);

  console.log("----------------------------------------------------");
  console.log("Deployment Summary:");
  console.log(`AuthorizationManager: ${authManagerAddress}`);
  console.log(`SecureVault:          ${vaultAddress}`);
  console.log("----------------------------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});