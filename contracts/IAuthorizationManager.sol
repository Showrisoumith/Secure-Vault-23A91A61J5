// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAuthorizationManager {
    /**
     * @notice Validates that a withdrawal is permitted.
     * @param receiver The address receiving the funds.
     * @param amount The amount to be withdrawn.
     * @param nonce A unique identifier for this specific authorization.
     * @param signature The cryptographic proof from the off-chain signer.
     * @return bool True if the authorization is valid and has been consumed.
     */
    function verifyAndUse(
        address receiver, 
        uint256 amount, 
        uint256 nonce, 
        bytes calldata signature
    ) external returns (bool);
}