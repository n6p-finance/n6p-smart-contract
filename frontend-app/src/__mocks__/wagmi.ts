// Mock for wagmi library
export const useAccount = jest.fn().mockReturnValue({
  address: '0x1234567890123456789012345678901234567890',
  isConnected: true,
  isConnecting: false,
  isDisconnected: false,
  status: 'connected',
});

export const useReadContract = jest.fn().mockReturnValue({
  data: null,
  isLoading: false,
  isError: false,
  error: null,
});

export const useWriteContract = jest.fn().mockReturnValue({
  writeContract: jest.fn(),
  isPending: false,
  isError: false,
  error: null,
});

export const useWaitForTransactionReceipt = jest.fn().mockReturnValue({
  data: null,
  isLoading: false,
  isError: false,
  error: null,
});

export const useBalance = jest.fn().mockReturnValue({
  data: {
    formatted: '1.5',
    symbol: 'ETH',
    value: BigInt(1500000000000000000),
  },
  isLoading: false,
  isError: false,
  error: null,
});

export const useEnsName = jest.fn().mockReturnValue({
  data: null,
  isLoading: false,
  isError: false,
  error: null,
});

export const useEnsAvatar = jest.fn().mockReturnValue({
  data: null,
  isLoading: false,
  isError: false,
  error: null,
});

export const useConnect = jest.fn().mockReturnValue({
  connect: jest.fn(),
  connectors: [],
  isPending: false,
  isError: false,
  error: null,
});

export const useDisconnect = jest.fn().mockReturnValue({
  disconnect: jest.fn(),
  isPending: false,
  isError: false,
  error: null,
});

export const useNetwork = jest.fn().mockReturnValue({
  chain: {
    id: 1,
    name: 'Ethereum',
  },
  chains: [
    {
      id: 1,
      name: 'Ethereum',
    },
    {
      id: 11155111,
      name: 'Sepolia',
    },
  ],
});

export const useSwitchNetwork = jest.fn().mockReturnValue({
  switchNetwork: jest.fn(),
  isPending: false,
  isError: false,
  error: null,
});

export const createConfig = jest.fn().mockReturnValue({});

export const http = jest.fn();

// Chain exports
export const mainnet = { id: 1, name: 'Ethereum' };
export const sepolia = { id: 11155111, name: 'Sepolia' };
export const hardhat = { id: 31337, name: 'Hardhat' };
export const anvil = { id: 31337, name: 'Anvil' };

// Mock WagmiConfig component
export const WagmiConfig = ({ children }: { children: React.ReactNode }) => children;
