'use client';

import { NavbarSpacer } from '@/components/Navbar';
import MarketConditions from '@/components/MarketConditions';
import React from 'react';

export default function MarketPage() {
  return (
    <>
      <NavbarSpacer />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-white mb-4">Market Monitor</h1>
          <p className="text-gray-300">
            Watch how NapFi AI adapts to changing market conditions in real-time to optimize your yield strategy.
          </p>
        </div>

        {/* Market Conditions Component */}
        <MarketConditions />
        
        {/* Additional information */}
        <div className="mt-8 bg-gray-800 rounded-xl shadow-lg border border-gray-700 overflow-hidden p-5">
          <h2 className="text-xl font-bold text-white mb-4">How NapFi AI Reacts to Markets</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-semibold text-blue-400 mb-3">Market-Adaptive AI</h3>
              <p className="text-gray-300 mb-4">
                NapFi AI continuously monitors market conditions across multiple indicators to make informed allocation decisions. 
                Unlike traditional static allocation models, our AI can react within minutes to significant market changes.
              </p>
              
              <ul className="list-disc list-inside text-gray-300 space-y-2 pl-2">
                <li>Analyzes market indices, volatility, interest rates, and more</li>
                <li>Identifies market regimes (bullish, bearish, volatile, neutral)</li>
                <li>Adjusts allocations based on risk-reward optimization</li>
                <li>Learns from historical performance to improve future decisions</li>
              </ul>
            </div>
            
            <div>
              <h3 className="text-lg font-semibold text-blue-400 mb-3">Market Condition Responses</h3>
              
              <div className="space-y-3">
                <div className="bg-green-900/30 border border-green-800 rounded-lg p-3">
                  <p className="font-medium text-green-400 mb-1">Bullish Markets</p>
                  <p className="text-sm text-gray-300">
                    Increases allocation to high-yield strategies to maximize returns during growth periods.
                  </p>
                </div>
                
                <div className="bg-red-900/30 border border-red-800 rounded-lg p-3">
                  <p className="font-medium text-red-400 mb-1">Bearish Markets</p>
                  <p className="text-sm text-gray-300">
                    Shifts to stable-yield strategies to preserve capital during market downturns.
                  </p>
                </div>
                
                <div className="bg-yellow-900/30 border border-yellow-800 rounded-lg p-3">
                  <p className="font-medium text-yellow-400 mb-1">Volatile Markets</p>
                  <p className="text-sm text-gray-300">
                    Rebalances toward balanced strategies to mitigate risk while maintaining growth potential.
                  </p>
                </div>
                
                <div className="bg-blue-900/30 border border-blue-800 rounded-lg p-3">
                  <p className="font-medium text-blue-400 mb-1">Neutral Markets</p>
                  <p className="text-sm text-gray-300">
                    Fine-tunes allocations based on subtle market signals and sector performance.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
