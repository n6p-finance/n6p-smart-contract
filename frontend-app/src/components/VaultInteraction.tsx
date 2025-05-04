'use client';

import React, { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useReadContract } from 'wagmi';
import { parseEther, formatEther, parseUnits, formatUnits } from 'viem';
import { CONTRACT_ADDRESSES } from '@/config/web3';
import VaultABI from '@/abi/Vault.json';
import TokenApproval from './TokenApproval';

/**
 * Component for interacting with the Vault contract (deposits and withdrawals)
 */
const VaultInteraction: React.FC = () => {
  const { address, isConnected } = useAccount();
  const [amount, setAmount] = useState<string>('');
  const [isDeposit, setIsDeposit] = useState<boolean>(true);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Use the vault address from our contract addresses configuration
  const vaultAddress = CONTRACT_ADDRESSES.vault;
  
  // TestToken address from our contract addresses configuration
  const tokenAddress = CONTRACT_ADDRESSES.testToken;
  
  // State to track if approval is needed
  const [needsApproval, setNeedsApproval] = useState<boolean>(true);
  
  // Token details
  const [tokenSymbol, setTokenSymbol] = useState<string>('NAPTEST');
  const [tokenDecimals, setTokenDecimals] = useState<number>(18);

  // Read user's share balance
  const { data: userShares } = useReadContract({
    address: vaultAddress as `0x${string}`,
    abi: VaultABI,
    functionName: 'balanceOf',
    args: [address as `0x${string}`],
    query: {
      enabled: Boolean(isConnected && address),
    }
  });

  // Read price per share
  const { data: pricePerShare } = useReadContract({
    address: vaultAddress as `0x${string}`,
    abi: VaultABI,
    functionName: 'getPricePerShare',
    query: {
      enabled: Boolean(isConnected),
    }
  });

  // Write contract function for deposit/withdraw
  const { writeContractAsync, isPending } = useWriteContract();

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setTxHash(null);

    if (!amount || parseFloat(amount) <= 0) {
      setError('Please enter a valid amount');
      return;
    }

    try {
      // Parse amount with proper decimals
      const parsedAmount = parseUnits(amount, tokenDecimals);
      
      // Call the appropriate function based on the action (deposit or withdraw)
      const hash = await writeContractAsync({
        address: vaultAddress as `0x${string}`,
        abi: VaultABI,
        functionName: isDeposit ? 'deposit' : 'withdraw',
        args: [parsedAmount],
      });
      
      setTxHash(hash);
    } catch (err: any) {
      console.error('Transaction error:', err);
      setError(err.message || 'Transaction failed');
    }
  };

  // Format user's share balance for display
  const formattedShares = userShares ? formatUnits(userShares as bigint, tokenDecimals) : '0';
  
  // Calculate estimated value based on shares and price per share
  const estimatedValue = userShares && pricePerShare
    ? formatUnits((userShares as bigint) * (pricePerShare as bigint) / BigInt(10**tokenDecimals), tokenDecimals)
    : '0';

  // Handle approval completion
  const handleApprovalComplete = () => {
    setNeedsApproval(false);
  };
  
  return (
    <div className="bg-white rounded-xl shadow-md p-6 max-w-lg mx-auto">
      <h2 className="text-xl font-semibold mb-6 text-gray-800">
        {isDeposit ? 'Deposit to Vault' : 'Withdraw from Vault'}
      </h2>
      
      {/* Show token approval component if needed */}
      {isDeposit && needsApproval && (
        <TokenApproval 
          tokenAddress={tokenAddress}
          spenderAddress={vaultAddress}
          onApprovalComplete={handleApprovalComplete}
        />
      )}

      {/* Balance display */}
      <div className="bg-gray-50 rounded-lg p-4 mb-6">
        <div className="flex justify-between">
          <span className="text-gray-600">Your Shares:</span>
          <span className="font-semibold">{formattedShares}</span>
        </div>
        <div className="flex justify-between mt-2">
          <span className="text-gray-600">Estimated Value:</span>
          <span className="font-semibold">{estimatedValue} {tokenSymbol}</span>
        </div>
      </div>

      {/* Toggle buttons */}
      <div className="flex mb-6">
        <button
          type="button"
          className={`flex-1 py-2 px-4 rounded-l-md ${
            isDeposit ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-800'
          }`}
          onClick={() => setIsDeposit(true)}
        >
          Deposit
        </button>
        <button
          type="button"
          className={`flex-1 py-2 px-4 rounded-r-md ${
            !isDeposit ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-800'
          }`}
          onClick={() => setIsDeposit(false)}
        >
          Withdraw
        </button>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit}>
        <div className="mb-4">
          <label htmlFor="amount" className="block text-sm font-medium text-gray-700 mb-1">
            Amount ({tokenSymbol})
          </label>
          <div className="relative">
            <input
              type="number"
              id="amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.0"
              step="0.01"
              min="0"
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 py-2 px-3"
              disabled={!isConnected || isPending}
            />
            {isDeposit && (
              <button
                type="button"
                className="absolute right-2 top-2 text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded"
                onClick={() => setAmount('0.1')} // Example amount
              >
                MAX
              </button>
            )}
          </div>
        </div>

        <button
          type="submit"
          className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
          disabled={!isConnected || isPending || !amount}
        >
          {isPending
            ? 'Processing...'
            : isDeposit
            ? 'Deposit to Vault'
            : 'Withdraw from Vault'}
        </button>
      </form>

      {/* Transaction status */}
      {txHash && (
        <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-md">
          <p className="text-green-800 text-sm">
            Transaction submitted! Hash:{' '}
            <a
              href={`https://etherscan.io/tx/${txHash}`}
              target="_blank"
              rel="noopener noreferrer"
              className="underline"
            >
              {txHash.slice(0, 10)}...{txHash.slice(-8)}
            </a>
          </p>
        </div>
      )}

      {/* Error message */}
      {error && (
        <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md">
          <p className="text-red-800 text-sm">{error}</p>
        </div>
      )}

      {/* Note for demo */}
      <div className="bg-yellow-50 p-4 rounded-md mb-4 border border-yellow-200">
        <p className="text-sm text-yellow-800">
          <strong>Note:</strong> This is connected to the Sepolia testnet. Make sure your wallet has some NAPTEST tokens.
        </p>
      </div>
    </div>
  );
};

export default VaultInteraction;
