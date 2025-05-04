// Mock for web3.tsx configuration
export const CONTRACT_ADDRESSES = {
  aiDecisionModule: '0x1234567890123456789012345678901234567890',
  controller: '0x2345678901234567890123456789012345678901',
  vault: '0x3456789012345678901234567890123456789012',
  strategies: {
    aave: '0x4567890123456789012345678901234567890123',
    compound: '0x5678901234567890123456789012345678901234',
  }
};

export const chains = [
  { id: 1, name: 'Ethereum' },
  { id: 11155111, name: 'Sepolia' },
  { id: 31337, name: 'Local Anvil' },
];

export const queryClient = {};

export const wallets = [
  { id: 'metamask', name: 'MetaMask' },
  { id: 'walletconnect', name: 'WalletConnect' },
];

// Default export for the config
const config = {
  chains,
  projectId: 'mock-project-id',
};

export default config;
