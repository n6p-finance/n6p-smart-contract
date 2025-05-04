'use client';

import React, { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import MCPDecisionCard from './mcp/MCPDecisionCard';
import LoadingSpinner from './ui/LoadingSpinner';
import ErrorDisplay from './ui/ErrorDisplay';
import { CONTRACT_ADDRESSES } from '@/config/web3';

/**
 * Dashboard component that displays user's portfolio and the latest MCP decision
 */
const Dashboard: React.FC = () => {
  const { address, isConnected } = useAccount();
  const [latestDecisionId, setLatestDecisionId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // In a real implementation, we would fetch the latest decision ID from an event or API
  // For the hackathon demo, we'll use a mock decision ID and simulate loading
  useEffect(() => {
    const loadDashboardData = async () => {
      try {
        // Simulate API call delay
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        if (isConnected) {
          // This would typically come from listening to events or an API call
          const mockDecisionId = '0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234';
          setLatestDecisionId(mockDecisionId);
        }
        
        setIsLoading(false);
      } catch (err) {
        console.error('Error loading dashboard data:', err);
        setError('Failed to load dashboard data. Please try again.');
        setIsLoading(false);
      }
    };
    
    loadDashboardData();
  }, [isConnected]);

  // Function to retry loading data
  const handleRetry = () => {
    setIsLoading(true);
    setError(null);
    // Re-trigger the effect by changing a dependency
    // In a real app, you would call your data fetching function directly
    setTimeout(() => {
      setIsLoading(false);
    }, 1000);
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" data-testid="dashboard-container">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-2xl font-bold text-gray-900">NapFi AI Dashboard</h1>
        <div className="bg-gray-100 px-4 py-2 rounded-full">
          <p className="text-sm font-mono">
            {isConnected 
              ? `Connected: ${address?.slice(0, 6)}...${address?.slice(-4)}` 
              : 'Not connected'}
          </p>
        </div>
      </div>
      
      {isLoading ? (
        <div className="py-12">
          <LoadingSpinner text="Loading dashboard data..." />
        </div>
      ) : error ? (
        <div className="py-8">
          <ErrorDisplay 
            message={error} 
            variant="card" 
            onRetry={handleRetry} 
          />
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6" role="list">
          <div className="bg-white rounded-xl shadow-md p-6" data-testid="dashboard-card">
            <h2 className="text-xl font-semibold mb-6 text-gray-800">Your Portfolio</h2>
            
            <div className="grid grid-cols-3 gap-4 mb-8">
              <div className="bg-gray-50 rounded-lg p-4 text-center">
                <h3 className="text-sm text-gray-600 mb-2">Total Value</h3>
                <p className="text-2xl font-bold text-gray-900">$10,245.67</p>
                <p className="text-sm text-green-600 mt-1">+2.4% (24h)</p>
              </div>
              <div className="bg-gray-50 rounded-lg p-4 text-center">
                <h3 className="text-sm text-gray-600 mb-2">Current APY</h3>
                <p className="text-2xl font-bold text-gray-900">4.2%</p>
                <p className="text-sm text-green-600 mt-1">+0.3% from last week</p>
              </div>
              <div className="bg-gray-50 rounded-lg p-4 text-center">
                <h3 className="text-sm text-gray-600 mb-2">Risk Score</h3>
                <p className="text-2xl font-bold text-gray-900">3.5/10</p>
                <p className="text-sm text-blue-600 mt-1">Low risk profile</p>
              </div>
            </div>
            
            <h3 className="text-lg font-semibold mb-4 text-gray-800">Current Allocation</h3>
            <div className="bg-gray-50 rounded-lg p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center">
                  <div className="w-3 h-3 rounded-full bg-blue-500 mr-2"></div>
                  <span className="text-gray-700">USDC Lending</span>
                </div>
                <span className="font-medium">45%</span>
              </div>
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center">
                  <div className="w-3 h-3 rounded-full bg-green-500 mr-2"></div>
                  <span className="text-gray-700">ETH Staking</span>
                </div>
                <span className="font-medium">30%</span>
              </div>
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center">
                  <div className="w-3 h-3 rounded-full bg-purple-500 mr-2"></div>
                  <span className="text-gray-700">Curve LP</span>
                </div>
                <span className="font-medium">15%</span>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-3 h-3 rounded-full bg-yellow-500 mr-2"></div>
                  <span className="text-gray-700">Balancer LP</span>
                </div>
                <span className="font-medium">10%</span>
              </div>
            </div>
          </div>
          
          <div data-testid="dashboard-card">
            <h2 className="text-xl font-semibold mb-4 text-gray-800">AI Decision Insights</h2>
            <p className="text-gray-600 mb-6">
              Understand why NapFi AI has allocated your funds this way
            </p>
            
            {isConnected ? (
              <MCPDecisionCard 
                decisionId={latestDecisionId || ''} 
                aiDecisionModuleAddress={CONTRACT_ADDRESSES.aiDecisionModule}
              />
            ) : (
              <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
                <p className="text-gray-600 mb-4">Connect your wallet to view AI allocation decisions</p>
              </div>
            )}
            
            <div className="mt-8">
              <h3 className="text-lg font-semibold mb-4 text-gray-800">Decision History</h3>
              <ul className="divide-y divide-gray-200">
                <li className="py-3 flex justify-between items-center">
                  <div>
                    <span className="text-sm text-gray-500 block">May 1, 2025</span>
                    <span className="text-gray-800">Initial allocation</span>
                  </div>
                  <button className="bg-gray-200 hover:bg-gray-300 text-gray-800 text-sm py-1 px-3 rounded transition-colors">View</button>
                </li>
                <li className="py-3 flex justify-between items-center">
                  <div>
                    <span className="text-sm text-gray-500 block">May 15, 2025</span>
                    <span className="text-gray-800">Rebalance due to market change</span>
                  </div>
                  <button className="bg-gray-200 hover:bg-gray-300 text-gray-800 text-sm py-1 px-3 rounded transition-colors">View</button>
                </li>
                <li className="py-3 flex justify-between items-center">
                  <div>
                    <span className="text-sm text-gray-500 block">June 1, 2025</span>
                    <span className="text-gray-800">Added new strategy</span>
                  </div>
                  <button className="bg-gray-200 hover:bg-gray-300 text-gray-800 text-sm py-1 px-3 rounded transition-colors">View</button>
                </li>
              </ul>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;
