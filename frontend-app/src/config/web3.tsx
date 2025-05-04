import { http } from 'wagmi';
import { sepolia, mainnet, hardhat, Chain } from 'wagmi/chains';
import { QueryClient } from '@tanstack/react-query';
import { getDefaultConfig, getDefaultWallets } from '@rainbow-me/rainbowkit';
import { createConfig } from 'wagmi';

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
export const chains = [localAnvil, sepolia, mainnet, hardhat] as const;

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

// Contract addresses - replace with your deployed contract addresses
export const CONTRACT_ADDRESSES = {
  aiDecisionModule: '0x1234567890123456789012345678901234567890', // Replace with actual address
};
