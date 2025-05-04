import React from 'react';

// Mock RainbowKit components and hooks
export const ConnectButton = {
  Custom: ({ children }: { children: any }) => {
    return children({
      account: {
        address: '0x1234567890123456789012345678901234567890',
        balanceDecimals: 18,
        balanceFormatted: '1.234',
        balanceSymbol: 'ETH',
        displayBalance: '1.234 ETH',
        displayName: '0x1234...7890',
        ensAvatar: null,
        ensName: null,
        hasPendingTransactions: false,
      },
      chain: {
        hasIcon: true,
        iconUrl: null,
        iconBackground: '#fff',
        id: 1,
        name: 'Ethereum',
        unsupported: false,
      },
      mounted: true,
      openAccountModal: jest.fn(),
      openChainModal: jest.fn(),
      openConnectModal: jest.fn(),
    });
  },
};

export const RainbowKitProvider = ({ children }: { children: React.ReactNode }) => (
  <div data-testid="rainbow-kit-provider">{children}</div>
);

export const getDefaultWallets = jest.fn().mockReturnValue({
  wallets: [
    { id: 'metamask', name: 'MetaMask' },
    { id: 'walletconnect', name: 'WalletConnect' },
  ],
});

export const getDefaultConfig = jest.fn().mockReturnValue({});

export const lightTheme = jest.fn().mockReturnValue({});
export const darkTheme = jest.fn().mockReturnValue({});
export const midnightTheme = jest.fn().mockReturnValue({});
