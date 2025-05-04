import { getDefaultConfig, getDefaultWallets } from '@rainbow-me/rainbowkit';
import { QueryClient } from '@tanstack/react-query';
import { createConfig, http } from 'wagmi';
import { Chain, hardhat, mainnet, sepolia } from 'wagmi/chains';

import { anvil } from "wagmi/chains";

// Configure the local Anvil chain with specific settings
const localAnvil: Chain = {
  ...anvil,
  id: 31337,
  name: "Local Anvil",
  nativeCurrency: {
    name: "Ethereum",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ["http://localhost:8545"],
    },
    public: {
      http: ["http://localhost:8545"],
    },
  },
};

// Create a query client for React Query
export const queryClient = new QueryClient();

// Define the chains we want to support
export const chains = [sepolia, localAnvil, mainnet] as const;

// Set up wallets
export const { wallets } = getDefaultWallets({
  appName: 'NapFi AI',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? "", // Get one at https://cloud.walletconnect.com
});

export default getDefaultConfig({
	appName: "NapFi AI",
	chains,
	projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? "",
	ssr: false,
});


// Create the wagmi config
export const config = createConfig({
  chains,
  transports: {
    [sepolia.id]: http(),
    [mainnet.id]: http(),
    [hardhat.id]: http('http://127.0.0.1:8545'),
  },
});

// Contract addresses - update with deployed contract addresses
export const CONTRACT_ADDRESSES = {
  // Sepolia Testnet addresses
  sepolia: {
    aiDecisionModule: '0x93F7d6566Aa4011aA7A0043Ddda4c6cCc3954BF7', // Deployed AIDecisionModule address
    vault: '0x9d1f10369b2e1d70c1ce54b49ebb60b33a444a56', // Deployed Vault address with TestToken
    testToken: '0x47112e1874336Dae68Bd14D0c4373902db63aB6F', // Deployed TestToken address
  },
  // Local development addresses
  local: {
    aiDecisionModule: '0x5FbDB2315678afecb367f032d93F642f64180aa3', // Local AIDecisionModule address
    vault: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', // Local Vault address
    testToken: '0x0000000000000000000000000000000000000000', // Placeholder for local TestToken
  },
  // Use the appropriate environment based on the current chain
  aiDecisionModule: process.env.NEXT_PUBLIC_USE_TESTNET === 'true' 
    ? '0x93F7d6566Aa4011aA7A0043Ddda4c6cCc3954BF7' // Sepolia AIDecisionModule address
    : '0x5FbDB2315678afecb367f032d93F642f64180aa3', // Local development address
  vault: process.env.NEXT_PUBLIC_USE_TESTNET === 'true'
    ? '0x9d1f10369b2e1d70c1ce54b49ebb60b33a444a56' // Sepolia Vault address with TestToken
    : '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', // Local development address
  testToken: process.env.NEXT_PUBLIC_USE_TESTNET === 'true'
    ? '0x47112e1874336Dae68Bd14D0c4373902db63aB6F' // Sepolia TestToken address
    : '0x0000000000000000000000000000000000000000', // Local development address
};
