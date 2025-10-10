// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

/**
 * This interface is here for the Vault to interact with different strategies.
 * Each vault should implement this interface to ensure compatibility.
 */

interface IVaultAPI { 
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function apiVersion() external view returns (string memory);

    // EIP-2612 permit function to allow gasless approvals
    function permit(
        address owner, 
        address spender, 
        uint256 value, 
        uint256 deadline, 
        bytes calldata signature) 
        external returns (bool);
    function getBalance(address account) external view returns (uint256);
    function deposit(uint256 amount) external;
    function withdraw(uint256 ShareMax) external;
    function token() external view returns (address);
    function strategies(uint256 _strategy) external view returns (address);
    function pricePerShare() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function depositLimit() external view returns (uint256);

    // View how much the Vault can borrow from this Strategy
    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);
    
    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain, 
        uint256 _loss, 
        uint256 _debtPayment) 
        external returns (uint256);
    
    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy(address _strategy) external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}