'use client';

import React, { useState, useEffect } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import { formatUnits } from 'viem';
import { CONTRACT_ADDRESSES } from '@/config/web3';
import VaultABI from '@/abi/Vault.json';

const VaultDebugger: React.FC = () => {
  const { address, isConnected } = useAccount();
  const [refreshKey, setRefreshKey] = useState<number>(0);
  
  // Vault address
  const vaultAddress = CONTRACT_ADDRESSES.vault as `0x${string}`;
  
  // Read user's share balance
  const { data: userShares, refetch: refetchShares } = useReadContract({
    address: vaultAddress,
    abi: VaultABI,
    functionName: 'balanceOf',
    args: [address as `0x${string}`],
    query: {
      enabled: Boolean(isConnected && address),
    }
  });

  // Read total supply
  const { data: totalSupply, refetch: refetchTotalSupply } = useReadContract({
    address: vaultAddress,
    abi: VaultABI,
    functionName: 'totalSupply',
    query: {
      enabled: Boolean(isConnected),
    }
  });

  // Read vault token balance
  const { data: vaultBalance, refetch: refetchVaultBalance } = useReadContract({
    address: vaultAddress,
    abi: VaultABI,
    functionName: '_getVaultBalance',
    query: {
      enabled: Boolean(isConnected),
    }
  });

  // Refresh all data
  const refreshData = () => {
    refetchShares();
    refetchTotalSupply();
    refetchVaultBalance();
    setRefreshKey(prev => prev + 1);
  };

  // Format values for display
  const formattedShares = userShares 
    ? formatUnits(userShares as bigint, 18) 
    : '0';
  
  const formattedTotalSupply = totalSupply 
    ? formatUnits(totalSupply as bigint, 18) 
    : '0';
    
  const formattedVaultBalance = vaultBalance 
    ? formatUnits(vaultBalance as bigint, 18) 
    : '0';

  return (
    <div className="bg-white rounded-xl shadow-md p-6 mb-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold text-gray-800">
          Vault Debug Information
        </h2>
        <button 
          onClick={refreshData}
          className="px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600 text-sm"
        >
          Refresh Data
        </button>
      </div>
      
      <div className="bg-blue-50 p-4 rounded-md mb-4 border border-blue-200">
        <p className="text-sm text-blue-800">
          <strong>Debug Info:</strong> This component shows detailed information about the Vault contract state.
        </p>
      </div>

      <div className="space-y-4">
        <div className="bg-gray-50 rounded-lg p-4">
          <h3 className="font-medium text-gray-700 mb-2">Vault Contract Information</h3>
          <div className="grid grid-cols-2 gap-2">
            <div className="text-gray-600">Vault Address:</div>
            <div className="font-mono text-sm break-all">{vaultAddress}</div>
            
            <div className="text-gray-600">Total Supply:</div>
            <div>{formattedTotalSupply} Shares</div>
            
            <div className="text-gray-600">Vault Token Balance:</div>
            <div>{formattedVaultBalance} NAPTEST</div>
          </div>
        </div>

        <div className="bg-gray-50 rounded-lg p-4">
          <h3 className="font-medium text-gray-700 mb-2">Your Vault Position</h3>
          <div className="grid grid-cols-2 gap-2">
            <div className="text-gray-600">Connected Address:</div>
            <div className="font-mono text-sm break-all">{address || 'Not connected'}</div>
            
            <div className="text-gray-600">Your Shares:</div>
            <div>{formattedShares} Shares</div>
            
            <div className="text-gray-600">Share Percentage:</div>
            <div>
              {totalSupply && userShares && Number(totalSupply) > 0
                ? ((Number(userShares) / Number(totalSupply)) * 100).toFixed(4) + '%'
                : '0%'}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VaultDebugger;
