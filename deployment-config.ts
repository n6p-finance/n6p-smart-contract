/**
 * N6P Finance - Base Sepolia Deployment Configuration
 * This file contains all addresses and configuration for the Base Sepolia network
 * Update this after running the deployment script
 */

export const BASE_SEPOLIA_CONFIG = {
  // Network Configuration
  chainId: 84532,
  chainName: "Base Sepolia",
  rpcUrl: "https://sepolia.base.org",
  
  // Deployment Addresses (Update after deployment)
  addresses: {
    registry: "0x0000000000000000000000000000000000000000",
    vaultDeFiImplementation: "0x0000000000000000000000000000000000000000",
    vaultRWAImplementation: "0x0000000000000000000000000000000000000000",
    feeOracle: "0x0000000000000000000000000000000000000000",
    healthCheck: "0x0000000000000000000000000000000000000000",
    baseStrategy: "0x0000000000000000000000000000000000000000",
  },

  // Key Roles and Configuration
  roles: {
    governance: "0x005684ac7c737bff821eccb377cc46e5a7dcb60d",
    management: "0x005684ac7c737bff821eccb377cc46e5a7dcb60d",
    guardian: "0x005684ac7c737bff821eccb377cc46e5a7dcb60d",
    rewards: "0x005684ac7c737bff821eccb377cc46e5a7dcb60d",
  },

  // Supported Tokens (Add tokens as they're supported)
  tokens: {
    // Example token configuration
    // USDC: {
    //   address: "0x...",
    //   decimals: 6,
    //   symbol: "USDC",
    //   name: "USD Coin",
    // },
  },

  // Deployed Vaults (Add vault proxies as they're created)
  vaults: {
    // Example vault configuration
    // usdcVault: {
    //   address: "0x...",
    //   tokenAddress: "0x...",
    //   apiVersion: "0.4.6",
    //   name: "USDC Vault",
    //   symbol: "nvUSDC",
    // },
  },

  // Contract Verification URLs (for Basescan)
  verificationUrls: {
    basescan: "https://sepolia.basescan.org/address/",
    blockscout: "https://base-sepolia.blockscout.com/address/",
  },
};

/**
 * Helper function to get vault proxy address for a token
 */
export function getVaultAddress(tokenSymbol: string): string {
  const vaultKey = `${tokenSymbol.toLowerCase()}Vault`;
  const vault = BASE_SEPOLIA_CONFIG.vaults[vaultKey as keyof typeof BASE_SEPOLIA_CONFIG.vaults];
  if (!vault) {
    throw new Error(`Vault not found for token: ${tokenSymbol}`);
  }
  return vault.address;
}

/**
 * Helper function to get token configuration
 */
export function getTokenConfig(symbol: string) {
  const token = BASE_SEPOLIA_CONFIG.tokens[symbol as keyof typeof BASE_SEPOLIA_CONFIG.tokens];
  if (!token) {
    throw new Error(`Token configuration not found: ${symbol}`);
  }
  return token;
}

/**
 * Get all deployed addresses
 */
export function getDeployedAddresses() {
  return BASE_SEPOLIA_CONFIG.addresses;
}

/**
 * Get all role addresses
 */
export function getRoleAddresses() {
  return BASE_SEPOLIA_CONFIG.roles;
}

/**
 * Validate all required addresses are configured (not 0x0)
 */
export function validateConfiguration(): boolean {
  const requiredAddresses = Object.values(BASE_SEPOLIA_CONFIG.addresses);
  return requiredAddresses.every(addr => addr !== "0x0000000000000000000000000000000000000000");
}

/**
 * Export configuration for environment file
 */
export function exportEnvConfig(): string {
  const config = BASE_SEPOLIA_CONFIG;
  return `
# N6P Finance - Base Sepolia Configuration
VITE_CHAIN_ID=${config.chainId}
VITE_CHAIN_NAME="${config.chainName}"
VITE_RPC_URL="${config.rpcUrl}"

# Contract Addresses
VITE_REGISTRY_ADDRESS="${config.addresses.registry}"
VITE_VAULT_DEFI_IMPL="${config.addresses.vaultDeFiImplementation}"
VITE_VAULT_RWA_IMPL="${config.addresses.vaultRWAImplementation}"
VITE_FEE_ORACLE="${config.addresses.feeOracle}"
VITE_HEALTH_CHECK="${config.addresses.healthCheck}"
VITE_BASE_STRATEGY="${config.addresses.baseStrategy}"

# Role Addresses
VITE_GOVERNANCE="${config.roles.governance}"
VITE_MANAGEMENT="${config.roles.management}"
VITE_GUARDIAN="${config.roles.guardian}"
VITE_REWARDS="${config.roles.rewards}"
`;
}

export default BASE_SEPOLIA_CONFIG;
