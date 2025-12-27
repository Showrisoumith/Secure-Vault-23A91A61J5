// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IAuthorizationManager.sol";

/**
 * @title SecureVault
 * @dev Holds pooled funds and executes withdrawals only after external authorization.
 */
contract SecureVault is ReentrancyGuard {
    IAuthorizationManager public immutable authorizationManager;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed receiver, uint256 amount);

    constructor(address _authManagerAddress) {
        require(_authManagerAddress != address(0), "Invalid manager address");
        authorizationManager = IAuthorizationManager(_authManagerAddress);
    }

    /**
     * @notice Accept deposits and track them via events.
     * Outcome: Deposits are accepted and tracked correctly.
     */
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Executes a withdrawal after confirming permission with the Manager.
     * @param receiver The address to receive the funds.
     * @param amount The amount of ETH to send.
     * @param nonce A unique identifier for the signature.
     * @param signature The proof provided by the off-chain coordinator.
     */
    function withdraw(
        address payable receiver,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external nonReentrant {
        // 1. Requirement: Request authorization validation
        // This call marks the authorization as "consumed" inside the Manager.
        bool isAuthorized = authorizationManager.verifyAndUse(
            receiver,
            amount,
            nonce,
            signature
        );

        require(isAuthorized, "SecureVault: Unauthorized withdrawal");

        // 2. Check: Ensure vault has enough funds
        require(address(this).balance >= amount, "SecureVault: Insufficient balance");

        // 3. Interaction: Transfer funds (Outcome: Execute after confirmation)
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "SecureVault: Transfer failed");

        // 4. Outcome: Behavior is observable via events
        emit Withdrawn(receiver, amount);
    }
}