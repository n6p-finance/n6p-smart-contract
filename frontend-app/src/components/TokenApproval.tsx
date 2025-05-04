'use client';

import React, { useState } from 'react';
import { useAccount, useWriteContract, useReadContract } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { CONTRACT_ADDRESSES } from '@/config/web3';

// Simple ERC20 ABI for approval
const ERC20_ABI = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "spender",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "value",
        "type": "uint256"
      }
    ],
    "name": "approve",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "balanceOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "symbol",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
];

interface TokenApprovalProps {
  tokenAddress: string;
  spenderAddress: string;
  onApprovalComplete?: () => void;
}

/**
 * Component for approving token spending
 */
const TokenApproval: React.FC<TokenApprovalProps> = ({ 
  tokenAddress, 
  spenderAddress,
  onApprovalComplete 
}) => {
  const { address, isConnected } = useAccount();
  const [amount, setAmount] = useState<string>('1000');
  const [txHash, setTxHash] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Read token symbol
  const { data: tokenSymbol } = useReadContract({
    address: tokenAddress as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'symbol',
    query: {
      enabled: Boolean(tokenAddress),
    }
  }) as { data: string | undefined };

  // Read user's token balance
  const { data: tokenBalance } = useReadContract({
    address: tokenAddress as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address as `0x${string}`],
    query: {
      enabled: Boolean(isConnected && address && tokenAddress),
    }
  });

  // Write contract function for approval
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
      const parsedAmount = parseEther(amount);
      
      // Approve token spending
      const hash = await writeContractAsync({
        address: tokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [spenderAddress as `0x${string}`, parsedAmount],
      });
      
      setTxHash(hash);
      
      // Call the callback if provided
      if (onApprovalComplete) {
        onApprovalComplete();
      }
    } catch (err: any) {
      console.error('Transaction error:', err);
      setError(err.message || 'Transaction failed');
    }
  };

  // Format token balance for display
  const formattedBalance = tokenBalance ? formatEther(tokenBalance as bigint) : '0';

  return (
    <div className="bg-white rounded-xl shadow-md p-6 mb-6">
      <h2 className="text-xl font-semibold mb-4 text-gray-800">
        Approve Token Spending
      </h2>
      
      <div className="bg-yellow-50 p-4 rounded-md mb-4 border border-yellow-200">
        <p className="text-sm text-yellow-800">
          <strong>Important:</strong> Before depositing, you need to approve the Vault contract to spend your {typeof tokenSymbol === 'string' ? tokenSymbol : 'tokens'}.
        </p>
      </div>

      {/* Balance display */}
      <div className="bg-gray-50 rounded-lg p-4 mb-4">
        <div className="flex justify-between">
          <span className="text-gray-600">Your {typeof tokenSymbol === 'string' ? tokenSymbol : 'Token'} Balance:</span>
          <span className="font-semibold">{formattedBalance}</span>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit}>
        <div className="mb-4">
          <label htmlFor="amount" className="block text-sm font-medium text-gray-700 mb-1">
            Amount to Approve
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
            <button
              type="button"
              className="absolute right-2 top-2 text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded"
              onClick={() => setAmount('1000')}
            >
              MAX
            </button>
          </div>
        </div>

        <button
          type="submit"
          className="w-full bg-green-600 hover:bg-green-700 text-white font-semibold py-3 px-4 rounded transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
          disabled={!isConnected || isPending || !amount}
        >
          {isPending
            ? 'Processing...'
            : `Approve ${tokenSymbol || 'Token'} Spending`}
        </button>
      </form>

      {/* Transaction status */}
      {txHash && (
        <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-md">
          <p className="text-green-800 text-sm">
            Approval submitted! Hash:{' '}
            <a
              href={`https://sepolia.etherscan.io/tx/${txHash}`}
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
    </div>
  );
};

export default TokenApproval;
