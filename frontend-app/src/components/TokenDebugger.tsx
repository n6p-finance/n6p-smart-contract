'use client';

import React, { useState, useEffect } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import { formatUnits } from 'viem';
import { CONTRACT_ADDRESSES } from '@/config/web3';

// Simple ERC20 ABI for balance and allowance checks
const ERC20_ABI = [
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
    "inputs": [
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "spender",
        "type": "address"
      }
    ],
    "name": "allowance",
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
  },
  {
    "inputs": [],
    "name": "decimals",
    "outputs": [
      {
        "internalType": "uint8",
        "name": "",
        "type": "uint8"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
];

const TokenDebugger: React.FC = () => {
  const { address, isConnected } = useAccount();
  const [tokenDecimals, setTokenDecimals] = useState<number>(18);
  
  // Token and vault addresses
  const tokenAddress = CONTRACT_ADDRESSES.testToken as `0x${string}`;
  const vaultAddress = CONTRACT_ADDRESSES.vault as `0x${string}`;
  
  // Read token symbol
  const { data: tokenSymbol } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI,
    functionName: 'symbol',
    query: {
      enabled: Boolean(tokenAddress),
    }
  });

  // Read token decimals
  const { data: decimals } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI,
    functionName: 'decimals',
    query: {
      enabled: Boolean(tokenAddress),
    }
  });

  // Read user's token balance
  const { data: tokenBalance } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address as `0x${string}`],
    query: {
      enabled: Boolean(isConnected && address && tokenAddress),
    }
  });

  // Read user's token allowance for the vault
  const { data: tokenAllowance } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: [address as `0x${string}`, vaultAddress],
    query: {
      enabled: Boolean(isConnected && address && tokenAddress && vaultAddress),
    }
  });

  // Update token decimals when data is available
  useEffect(() => {
    if (decimals) {
      setTokenDecimals(Number(decimals));
    }
  }, [decimals]);

  // Format values for display
  const formattedBalance = tokenBalance 
    ? formatUnits(tokenBalance as bigint, tokenDecimals) 
    : '0';
  
  const formattedAllowance = tokenAllowance 
    ? formatUnits(tokenAllowance as bigint, tokenDecimals) 
    : '0';

  return (
    <div className="bg-white rounded-xl shadow-md p-6 mb-6">
      <h2 className="text-xl font-semibold mb-4 text-gray-800">
        Token Debugger
      </h2>
      
      <div className="bg-blue-50 p-4 rounded-md mb-4 border border-blue-200">
        <p className="text-sm text-blue-800">
          <strong>Debug Info:</strong> This component shows your token balance and allowance to help debug deposit issues.
        </p>
      </div>

      <div className="space-y-4">
        <div className="bg-gray-50 rounded-lg p-4">
          <h3 className="font-medium text-gray-700 mb-2">Token Information</h3>
          <div className="grid grid-cols-2 gap-2">
            <div className="text-gray-600">Token Address:</div>
            <div className="font-mono text-sm break-all">{tokenAddress}</div>
            
            <div className="text-gray-600">Vault Address:</div>
            <div className="font-mono text-sm break-all">{vaultAddress}</div>
            
            <div className="text-gray-600">Token Symbol:</div>
            <div>{tokenSymbol ? String(tokenSymbol) : 'Loading...'}</div>
            
            <div className="text-gray-600">Token Decimals:</div>
            <div>{String(tokenDecimals)}</div>
          </div>
        </div>

        <div className="bg-gray-50 rounded-lg p-4">
          <h3 className="font-medium text-gray-700 mb-2">Your Wallet</h3>
          <div className="grid grid-cols-2 gap-2">
            <div className="text-gray-600">Connected Address:</div>
            <div className="font-mono text-sm break-all">{address || 'Not connected'}</div>
            
            <div className="text-gray-600">Token Balance:</div>
            <div>{formattedBalance} {tokenSymbol ? String(tokenSymbol) : ''}</div>
            
            <div className="text-gray-600">Allowance for Vault:</div>
            <div>{formattedAllowance} {tokenSymbol ? String(tokenSymbol) : ''}</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TokenDebugger;
