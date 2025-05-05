import { getDefaultConfig, getDefaultWallets } from '@rainbow-me/rainbowkit';
import { createConfig, http } from 'wagmi';
import { Chain, sepolia } from 'wagmi/chains';

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

// Define the chains we want to support
export const chains = [sepolia] as const;

// Set up wallets
export const { wallets } = getDefaultWallets({
  appName: 'NapFi AI',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? "47ef282c9343d40209929de4d60d58cb", // Get one at https://cloud.walletconnect.com
});

export default getDefaultConfig({
	appName: "NapFi AI",
	chains,
	projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? "47ef282c9343d40209929de4d60d58cb",
	ssr: false,
});


// Create the wagmi config
export const config = createConfig({
  chains,
  transports: {
    [sepolia.id]: http(),
  },
});

// Contract addresses - update with deployed contract addresses
export const CONTRACT_ADDRESSES = {
  // Sepolia Testnet addresses
  sepolia: {
    aiDecisionModule: process.env.NEXT_PUBLIC_AI_DECISION_MODULE_ADDRESS ?? '0x93F7d6566Aa4011aA7A0043Ddda4c6cCc3954BF7', // Deployed AIDecisionModule address
    vault: '0x616102e0C0af01aF67a877031a199d880178913D', // Updated TestVault address with controller support
    testToken: '0x47112e1874336Dae68Bd14D0c4373902db63aB6F', // Deployed TestToken address
    testController: '0x92FcbFaa42AD84d0EF230AA5e38eaEa4af129fc9', // Deployed TestController address
    testStrategy: '0x377ea45291DED69A76a9959d32745af618Cc1C26', // Deployed TestStrategy address (5% APY)
    highYieldStrategy: '0xFA7F6451901f15bdAEF0FD72329bFD8dd352f432', // High-Yield Strategy (8% APY)
    stableYieldStrategy: '0xD72A532f0a4AdBE46c0BC2026bA57DC977021b1B', // Stable-Yield Strategy (3% APY)
  },
  // Local development addresses
  local: {
    aiDecisionModule: '0x5FbDB2315678afecb367f032d93F642f64180aa3', // Local AIDecisionModule address
    vault: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', // Local Vault address
    testToken: '0x0000000000000000000000000000000000000000', // Placeholder for local TestToken
    testController: '0x0000000000000000000000000000000000000000', // Placeholder for local TestController
    testStrategy: '0x0000000000000000000000000000000000000000', // Placeholder for local TestStrategy
  },
  // Use the appropriate environment based on the current chain
  aiDecisionModule: process.env.NEXT_PUBLIC_USE_TESTNET === 'true' 
    ? '0x93F7d6566Aa4011aA7A0043Ddda4c6cCc3954BF7' // Sepolia AIDecisionModule address
    : '0x5FbDB2315678afecb367f032d93F642f64180aa3', // Local development address
  vault: process.env.NEXT_PUBLIC_USE_TESTNET === 'true'
    ? '0xCe20CA4FD82f03Bbbbd4c79cf8516E05F6457426' // Sepolia TestVault address
    : '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', // Local development address
  testToken: process.env.NEXT_PUBLIC_USE_TESTNET === 'true'
    ? '0x47112e1874336Dae68Bd14D0c4373902db63aB6F' // Sepolia TestToken address
    : '0x0000000000000000000000000000000000000000', // Local development address
};
