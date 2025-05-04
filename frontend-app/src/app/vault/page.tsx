'use client';

import React from 'react';
import VaultInteraction from '@/components/VaultInteraction';
import TokenDebugger from '@/components/TokenDebugger';
import VaultDebugger from '@/components/VaultDebugger';

export default function VaultPage() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-4">Vault Operations</h1>
        <p className="text-gray-600">
          Deposit your funds into the NapFi AI vault to start earning optimized yields, or withdraw your funds at any time.
        </p>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div className="space-y-6">
          <TokenDebugger />
          <VaultDebugger />
          <VaultInteraction />
        </div>
        
        <div className="bg-white rounded-xl shadow-md p-6">
          <h2 className="text-xl font-semibold mb-6 text-gray-800">How It Works</h2>
          
          <div className="space-y-4">
            <div className="flex items-start">
              <div className="flex-shrink-0 h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold">1</div>
              <div className="ml-4">
                <h3 className="text-lg font-medium text-gray-900">Deposit</h3>
                <p className="mt-1 text-gray-600">Deposit your tokens into the NapFi AI vault. You'll receive vault shares representing your portion of the pool.</p>
              </div>
            </div>
            
            <div className="flex items-start">
              <div className="flex-shrink-0 h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold">2</div>
              <div className="ml-4">
                <h3 className="text-lg font-medium text-gray-900">AI Allocation</h3>
                <p className="mt-1 text-gray-600">NapFi AI automatically allocates your funds across multiple strategies to maximize yield while managing risk.</p>
              </div>
            </div>
            
            <div className="flex items-start">
              <div className="flex-shrink-0 h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold">3</div>
              <div className="ml-4">
                <h3 className="text-lg font-medium text-gray-900">Earn Yield</h3>
                <p className="mt-1 text-gray-600">Your funds earn yield from various DeFi protocols. The AI continuously rebalances to optimize returns.</p>
              </div>
            </div>
            
            <div className="flex items-start">
              <div className="flex-shrink-0 h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold">4</div>
              <div className="ml-4">
                <h3 className="text-lg font-medium text-gray-900">Withdraw Anytime</h3>
                <p className="mt-1 text-gray-600">You can withdraw your funds at any time. Your shares will be converted back to the underlying tokens plus earned yield.</p>
              </div>
            </div>
          </div>
          
          <div className="mt-8 p-4 bg-yellow-50 rounded-lg border border-yellow-200">
            <h3 className="text-md font-semibold text-yellow-800 mb-2">Important Note</h3>
            <p className="text-sm text-yellow-700">
              This is a local development environment connected to your Anvil instance. In a production environment, you would be interacting with contracts deployed on Ethereum mainnet or a testnet.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
