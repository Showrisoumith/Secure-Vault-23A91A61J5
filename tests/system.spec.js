const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SecureVault System Integration", function () {
  let vault, authManager, owner, receiver;
  const amount = ethers.parseEther("1.0");
  const nonce = 12345n;

  beforeEach(async function () {
    [owner, receiver] = await ethers.getSigners();

    const AuthManager = await ethers.getContractFactory("AuthorizationManager");
    authManager = await AuthManager.deploy(owner.address);

    const Vault = await ethers.getContractFactory("SecureVault");
    vault = await Vault.deploy(await authManager.getAddress());

    await owner.sendTransaction({
      to: await vault.getAddress(),
      value: ethers.parseEther("10.0"),
    });
  });

  async function getSignature(receiverAddr, withdrawAmount, withdrawNonce) {
    const vaultAddress = await vault.getAddress();
    const chainId = (await ethers.provider.getNetwork()).chainId;

    // Use abiCoder to match Solidity's abi.encode perfectly
    const domainSeparator = ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "address", "uint256", "uint256", "uint256"],
      [vaultAddress, receiverAddr, withdrawAmount, withdrawNonce, chainId]
    );
    
    const hash = ethers.keccak256(domainSeparator);
    return await owner.signMessage(ethers.getBytes(hash));
  }

  it("Should allow a valid withdrawal with a correct signature", async function () {
    const signature = await getSignature(receiver.address, amount, nonce);

    await expect(vault.withdraw(receiver.address, amount, nonce, signature))
      .to.emit(vault, "Withdrawn")
      .withArgs(receiver.address, amount);
  });

  it("Should fail if the same authorization is reused (Replay Protection)", async function () {
    const signature = await getSignature(receiver.address, amount, nonce);

    // First one works
    await vault.withdraw(receiver.address, amount, nonce, signature);

    // Second one fails
    await expect(
      vault.withdraw(receiver.address, amount, nonce, signature)
    ).to.be.revertedWith("Authorization already consumed");
  });

  it("Should fail if the signature is modified or signed by an untrusted account", async function () {
    // This logic is already working!
    const vaultAddress = await vault.getAddress();
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const hash = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "address", "uint256", "uint256", "uint256"],
        [vaultAddress, receiver.address, amount, nonce, chainId]
    ));
    
    const [, , attacker] = await ethers.getSigners();
    const badSignature = await attacker.signMessage(ethers.getBytes(hash));

    await expect(
      vault.withdraw(receiver.address, amount, nonce, badSignature)
    ).to.be.revertedWith("Invalid authorization signature");
  });
});