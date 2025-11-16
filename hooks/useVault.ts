/**
 * N6P Finance - React Hooks for Vault Interactions
 * 
 * This file provides reusable React hooks for common vault operations.
 * Usage: 
 *   import { useVaultBalance, useVaultDeposit } from './hooks/useVault';
 */

import { useState, useCallback, useEffect } from 'react';
import { usePublicClient, useWalletClient } from 'wagmi';
import { getContract } from 'viem';
import { BASE_SEPOLIA_CONFIG, getVaultAddress } from '../deployment-config';
import * as ContractABIs from '../abis';

// ============================================================================
// READ HOOKS
// ============================================================================

/**
 * Hook to fetch vault information
 */
export function useVaultInfo(vaultAddress: string) {
  const [info, setInfo] = useState({
    name: '',
    symbol: '',
    asset: '0x',
    totalAssets: 0n,
    totalSupply: 0n,
    apiVersion: '',
    shutdown: false,
    loading: true,
    error: null as Error | null,
  });

  const publicClient = usePublicClient();

  useEffect(() => {
    if (!publicClient || !vaultAddress) return;

    const fetchInfo = async () => {
      try {
        const vault = getContract({
          address: vaultAddress as `0x${string}`,
          abi: ContractABIs.VaultDeFi,
          client: { public: publicClient },
        });

        const [name, symbol, asset, totalAssets, totalSupply, apiVersion, shutdown] =
          await Promise.all([
            vault.read.name(),
            vault.read.symbol(),
            vault.read.asset(),
            vault.read.totalAssets(),
            vault.read.totalSupply(),
            vault.read.apiVersion?.() ?? Promise.resolve('0.4.6'),
            vault.read.shutdown?.() ?? Promise.resolve(false),
          ]);

        setInfo({
          name: name as string,
          symbol: symbol as string,
          asset: asset as string,
          totalAssets: totalAssets as bigint,
          totalSupply: totalSupply as bigint,
          apiVersion: apiVersion as string,
          shutdown: shutdown as boolean,
          loading: false,
          error: null,
        });
      } catch (error) {
        setInfo(prev => ({
          ...prev,
          loading: false,
          error: error instanceof Error ? error : new Error('Unknown error'),
        }));
      }
    };

    fetchInfo();
  }, [publicClient, vaultAddress]);

  return info;
}

/**
 * Hook to fetch user's vault balance and equivalent assets
 */
export function useVaultBalance(vaultAddress: string, userAddress?: string) {
  const [balance, setBalance] = useState({
    shares: 0n,
    assets: 0n,
    loading: true,
    error: null as Error | null,
  });

  const publicClient = usePublicClient();

  useEffect(() => {
    if (!publicClient || !vaultAddress || !userAddress) {
      setBalance(prev => ({ ...prev, loading: false }));
      return;
    }

    const fetchBalance = async () => {
      try {
        const vault = getContract({
          address: vaultAddress as `0x${string}`,
          abi: ContractABIs.VaultDeFi,
          client: { public: publicClient },
        });

        const shares = (await vault.read.balanceOf([
          userAddress as `0x${string}`,
        ])) as bigint;
        const assets = (await vault.read.convertToAssets([shares])) as bigint;

        setBalance({
          shares,
          assets,
          loading: false,
          error: null,
        });
      } catch (error) {
        setBalance(prev => ({
          ...prev,
          loading: false,
          error: error instanceof Error ? error : new Error('Unknown error'),
        }));
      }
    };

    fetchBalance();
  }, [publicClient, vaultAddress, userAddress]);

  return balance;
}

/**
 * Hook to calculate conversion between shares and assets
 */
export function useConvertToAssets(vaultAddress: string, shares: bigint) {
  const [assets, setAssets] = useState(0n);
  const publicClient = usePublicClient();

  useEffect(() => {
    if (!publicClient || !vaultAddress || shares === 0n) {
      setAssets(0n);
      return;
    }

    const convert = async () => {
      try {
        const vault = getContract({
          address: vaultAddress as `0x${string}`,
          abi: ContractABIs.VaultDeFi,
          client: { public: publicClient },
        });

        const result = (await vault.read.convertToAssets([shares])) as bigint;
        setAssets(result);
      } catch (error) {
        console.error('Conversion error:', error);
      }
    };

    convert();
  }, [publicClient, vaultAddress, shares]);

  return assets;
}

/**
 * Hook to calculate conversion between assets and shares
 */
export function useConvertToShares(vaultAddress: string, assets: bigint) {
  const [shares, setShares] = useState(0n);
  const publicClient = usePublicClient();

  useEffect(() => {
    if (!publicClient || !vaultAddress || assets === 0n) {
      setShares(0n);
      return;
    }

    const convert = async () => {
      try {
        const vault = getContract({
          address: vaultAddress as `0x${string}`,
          abi: ContractABIs.VaultDeFi,
          client: { public: publicClient },
        });

        const result = (await vault.read.convertToShares([assets])) as bigint;
        setShares(result);
      } catch (error) {
        console.error('Conversion error:', error);
      }
    };

    convert();
  }, [publicClient, vaultAddress, assets]);

  return shares;
}

/**
 * Hook to fetch user's token balance and allowance
 */
export function useTokenBalance(
  tokenAddress: string,
  userAddress?: string,
  spenderAddress?: string,
) {
  const [data, setData] = useState({
    balance: 0n,
    allowance: 0n,
    loading: true,
    error: null as Error | null,
  });

  const publicClient = usePublicClient();

  useEffect(() => {
    if (!publicClient || !tokenAddress || !userAddress) {
      setData(prev => ({ ...prev, loading: false }));
      return;
    }

    const fetchData = async () => {
      try {
        const token = getContract({
          address: tokenAddress as `0x${string}`,
          abi: ContractABIs.ERC20,
          client: { public: publicClient },
        });

        const balance = (await token.read.balanceOf([
          userAddress as `0x${string}`,
        ])) as bigint;

        let allowance = 0n;
        if (spenderAddress) {
          allowance = (await token.read.allowance([
            userAddress as `0x${string}`,
            spenderAddress as `0x${string}`,
          ])) as bigint;
        }

        setData({
          balance,
          allowance,
          loading: false,
          error: null,
        });
      } catch (error) {
        setData(prev => ({
          ...prev,
          loading: false,
          error: error instanceof Error ? error : new Error('Unknown error'),
        }));
      }
    };

    fetchData();
  }, [publicClient, tokenAddress, userAddress, spenderAddress]);

  return data;
}

// ============================================================================
// WRITE HOOKS
// ============================================================================

/**
 * Hook for token approval
 */
export function useTokenApprove() {
  const walletClient = useWalletClient();
  const publicClient = usePublicClient();
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const approve = useCallback(
    async (
      tokenAddress: string,
      spenderAddress: string,
      amount: bigint,
      userAddress: string,
    ) => {
      setIsPending(true);
      setError(null);

      try {
        if (!walletClient.data) throw new Error('Wallet not connected');

        const hash = await walletClient.data.writeContract({
          address: tokenAddress as `0x${string}`,
          abi: ContractABIs.ERC20,
          functionName: 'approve',
          args: [spenderAddress as `0x${string}`, amount],
          account: userAddress as `0x${string}`,
        });

        const receipt = await publicClient!.waitForTransactionReceipt({
          hash,
        });

        setIsPending(false);
        return { hash, receipt };
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Unknown error');
        setError(error);
        setIsPending(false);
        throw error;
      }
    },
    [walletClient, publicClient],
  );

  return { approve, isPending, error };
}

/**
 * Hook for vault deposit
 */
export function useVaultDeposit() {
  const walletClient = useWalletClient();
  const publicClient = usePublicClient();
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const deposit = useCallback(
    async (
      vaultAddress: string,
      amount: bigint,
      userAddress: string,
      receiverAddress?: string,
    ) => {
      setIsPending(true);
      setError(null);

      try {
        if (!walletClient.data) throw new Error('Wallet not connected');

        const receiver = (receiverAddress || userAddress) as `0x${string}`;

        const hash = await walletClient.data.writeContract({
          address: vaultAddress as `0x${string}`,
          abi: ContractABIs.VaultDeFi,
          functionName: 'deposit',
          args: [amount, receiver],
          account: userAddress as `0x${string}`,
        });

        const receipt = await publicClient!.waitForTransactionReceipt({
          hash,
        });

        setIsPending(false);
        return { hash, receipt };
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Unknown error');
        setError(error);
        setIsPending(false);
        throw error;
      }
    },
    [walletClient, publicClient],
  );

  return { deposit, isPending, error };
}

/**
 * Hook for vault withdrawal
 */
export function useVaultWithdraw() {
  const walletClient = useWalletClient();
  const publicClient = usePublicClient();
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const withdraw = useCallback(
    async (
      vaultAddress: string,
      maxAssets: bigint,
      userAddress: string,
      receiverAddress?: string,
      ownerAddress?: string,
    ) => {
      setIsPending(true);
      setError(null);

      try {
        if (!walletClient.data) throw new Error('Wallet not connected');

        const receiver = (receiverAddress || userAddress) as `0x${string}`;
        const owner = (ownerAddress || userAddress) as `0x${string}`;

        const hash = await walletClient.data.writeContract({
          address: vaultAddress as `0x${string}`,
          abi: ContractABIs.VaultDeFi,
          functionName: 'withdraw',
          args: [maxAssets, receiver, owner],
          account: userAddress as `0x${string}`,
        });

        const receipt = await publicClient!.waitForTransactionReceipt({
          hash,
        });

        setIsPending(false);
        return { hash, receipt };
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Unknown error');
        setError(error);
        setIsPending(false);
        throw error;
      }
    },
    [walletClient, publicClient],
  );

  return { withdraw, isPending, error };
}

/**
 * Hook for vault redeem (shares for assets)
 */
export function useVaultRedeem() {
  const walletClient = useWalletClient();
  const publicClient = usePublicClient();
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const redeem = useCallback(
    async (
      vaultAddress: string,
      shares: bigint,
      userAddress: string,
      receiverAddress?: string,
      ownerAddress?: string,
    ) => {
      setIsPending(true);
      setError(null);

      try {
        if (!walletClient.data) throw new Error('Wallet not connected');

        const receiver = (receiverAddress || userAddress) as `0x${string}`;
        const owner = (ownerAddress || userAddress) as `0x${string}`;

        const hash = await walletClient.data.writeContract({
          address: vaultAddress as `0x${string}`,
          abi: ContractABIs.VaultDeFi,
          functionName: 'redeem',
          args: [shares, receiver, owner],
          account: userAddress as `0x${string}`,
        });

        const receipt = await publicClient!.waitForTransactionReceipt({
          hash,
        });

        setIsPending(false);
        return { hash, receipt };
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Unknown error');
        setError(error);
        setIsPending(false);
        throw error;
      }
    },
    [walletClient, publicClient],
  );

  return { redeem, isPending, error };
}

// ============================================================================
// COMBINED HOOKS
// ============================================================================

/**
 * Hook for complete deposit flow (approve + deposit)
 */
export function useDepositFlow() {
  const { approve } = useTokenApprove();
  const { deposit } = useVaultDeposit();
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const executeDeposit = useCallback(
    async (
      tokenAddress: string,
      vaultAddress: string,
      amount: bigint,
      userAddress: string,
    ) => {
      setIsPending(true);
      setError(null);

      try {
        // Approve
        await approve(tokenAddress, vaultAddress, amount, userAddress);

        // Deposit
        const result = await deposit(vaultAddress, amount, userAddress);

        setIsPending(false);
        return result;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Unknown error');
        setError(error);
        setIsPending(false);
        throw error;
      }
    },
    [approve, deposit],
  );

  return { executeDeposit, isPending, error };
}

/**
 * Hook to listen to vault events
 */
export function useVaultEvents(
  vaultAddress: string,
  eventName: 'Deposit' | 'Withdraw' | 'Redeem' | 'StrategyChanged' | 'Shutdown',
  onEvent: (log: any) => void,
) {
  const publicClient = usePublicClient();

  useEffect(() => {
    if (!publicClient || !vaultAddress) return;

    const unwatch = publicClient.watchContractEvent({
      address: vaultAddress as `0x${string}`,
      abi: ContractABIs.VaultDeFi,
      eventName: eventName,
      onLogs: (logs) => {
        logs.forEach(onEvent);
      },
    });

    return () => {
      unwatch();
    };
  }, [publicClient, vaultAddress, eventName, onEvent]);
}

// ============================================================================
// UTILITY HOOKS
// ============================================================================

/**
 * Hook to check if connected user can deposit
 */
export function useCanDeposit(
  vaultAddress: string,
  userAddress?: string,
  depositAmount?: bigint,
) {
  const vaultInfo = useVaultInfo(vaultAddress);
  const [canDeposit, setCanDeposit] = useState(false);

  useEffect(() => {
    if (!userAddress || !depositAmount) {
      setCanDeposit(false);
      return;
    }

    if (vaultInfo.loading || vaultInfo.error) {
      setCanDeposit(false);
      return;
    }

    // Check if vault is shutdown
    if (vaultInfo.shutdown) {
      setCanDeposit(false);
      return;
    }

    setCanDeposit(true);
  }, [vaultInfo, userAddress, depositAmount]);

  return canDeposit;
}

/**
 * Hook to format numbers for display
 */
export function useFormatToken(amount: bigint, decimals: number = 6): string {
  return (Number(amount) / Math.pow(10, decimals)).toFixed(decimals);
}

export default {
  // Read hooks
  useVaultInfo,
  useVaultBalance,
  useConvertToAssets,
  useConvertToShares,
  useTokenBalance,

  // Write hooks
  useTokenApprove,
  useVaultDeposit,
  useVaultWithdraw,
  useVaultRedeem,

  // Combined hooks
  useDepositFlow,
  useVaultEvents,

  // Utility hooks
  useCanDeposit,
  useFormatToken,
};
