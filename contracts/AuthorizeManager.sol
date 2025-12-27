// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./IAuthorizationManager.sol";

contract AuthorizationManager is IAuthorizationManager {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public immutable trustedSigner;
    
    // Mapping to prevent reuse (Outcome: Permissions cannot be reused)
    mapping(bytes32 => bool) public consumedAuthorizations;

    event AuthorizationConsumed(bytes32 indexed authHash, address indexed receiver, uint256 amount);

    constructor(address _trustedSigner) {
        require(_trustedSigner != address(0), "Invalid signer");
        trustedSigner = _trustedSigner;
    }

    /**
     * @dev Validates and marks an authorization as used.
     * Follows Checks-Effects-Interactions: Updates state before returning.
     */
    function verifyAndUse(
        address receiver,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external override returns (bool) {
        // 1. Build a deterministic, scoped hash (Common Mistake: Ambiguous data)
        bytes32 authHash = keccak256(
            abi.encode(
                msg.sender, // The Vault address calling this
                receiver,
                amount,
                nonce,
                block.chainid
            )
        );

        // 2. Ensure authorization has not been used before
        require(!consumedAuthorizations[authHash], "Authorization already consumed");

        // 3. Validate authenticity (Verify the signature)
        bytes32 ethSignedMessageHash = authHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(signature);
        
        require(signer == trustedSigner, "Invalid authorization signature");

        // 4. Mark as consumed BEFORE returning (Outcome: State transitions occur exactly once)
        consumedAuthorizations[authHash] = true;

        emit AuthorizationConsumed(authHash, receiver, amount);
        
        return true;
    }
}