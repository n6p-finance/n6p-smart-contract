'use client';

import React, { useState, useEffect } from 'react';
import { useReadContract } from 'wagmi';
import { CONTRACT_ADDRESSES } from '@/config/web3';
import AIDecisionModuleABI from '@/abi/AIDecisionModule.json';

interface MCPDecisionCardProps {
  decisionId: string;
  aiDecisionModuleAddress?: string;
}

interface Decision {
  id: string;
  timestamp: string;
  reasoning: string;
  strategies: string[];
  allocations: string[];
  signature: string;
}

/**
 * Component to display MCP decision reasoning
 * This is used in the dashboard to show users why their funds are allocated in a specific way
 */
const MCPDecisionCard: React.FC<MCPDecisionCardProps> = ({ 
  decisionId, 
  aiDecisionModuleAddress = CONTRACT_ADDRESSES.aiDecisionModule 
}) => {
  const [decision, setDecision] = useState<Decision | null>(null);

  // Read decision data from the contract
  const { data, isLoading, isError, error } = useReadContract({
    address: aiDecisionModuleAddress as `0x${string}`,
    abi: AIDecisionModuleABI,
    functionName: 'getDecision',
    args: [decisionId as `0x${string}`],
    query: {
      enabled: Boolean(decisionId && aiDecisionModuleAddress),
    }
  });

  useEffect(() => {
    if (data) {
      const [id, timestamp, reasoning, strategies, allocations, signature] = data as any;
      
      // Format the data for display
      const formattedDecision = {
        id,
        timestamp: new Date(Number(timestamp) * 1000).toLocaleString(),
        reasoning,
        strategies,
        allocations: allocations.map((a: bigint) => `${(Number(a) / 100).toFixed(1)}%`),
        signature: `${signature.slice(0, 10)}...`
      };
      
      setDecision(formattedDecision);
    }
  }, [data]);

  // For demo purposes, if we're not connected to a real contract, show mock data
  useEffect(() => {
    if (isError || (!isLoading && !data)) {
      // Mock data for demonstration
      setDecision({
        id: decisionId,
        timestamp: new Date().toLocaleString(),
        reasoning: "Aave currently offers a higher APY (4.2% vs 3.1%) with similar risk profile. Market conditions favor lending protocols with larger liquidity pools, making Aave a more stable option in the current environment.",
        strategies: [
          "0x1111111111111111111111111111111111111111",
          "0x2222222222222222222222222222222222222222"
        ],
        allocations: ["70.0%", "30.0%"],
        signature: "0xabcdef123..."
      });
    }
  }, [isError, isLoading, data, decisionId]);

  // Render loading state
  if (isLoading) {
    return (
      <div className="bg-gray-800 rounded-xl shadow-md overflow-hidden transition-all hover:shadow-lg border border-gray-700">
        <div className="bg-blue-800 text-white px-5 py-4 flex justify-between items-center">
          <h3 className="text-lg font-semibold m-0">AI Decision Reasoning</h3>
        </div>
        <div className="p-5 flex justify-center items-center min-h-[200px]">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
          <p className="ml-3 text-gray-300">Loading decision data...</p>
        </div>
      </div>
    );
  }

  // Render error state
  if (isError && !decision) {
    return (
      <div className="bg-gray-800 rounded-xl shadow-md overflow-hidden transition-all hover:shadow-lg border border-red-700">
        <div className="bg-red-800 text-white px-5 py-4 flex justify-between items-center">
          <h3 className="text-lg font-semibold m-0">AI Decision Reasoning</h3>
        </div>
        <div className="p-5">
          <p className="text-red-400">Error loading decision data</p>
          <p className="text-gray-400 text-sm mt-2">{(error as Error)?.message || 'Unknown error'}</p>
        </div>
      </div>
    );
  }

  // Render decision data
  return (
    <div className="bg-gray-800 rounded-xl shadow-md overflow-hidden transition-all hover:shadow-lg hover:translate-y-[-2px] border border-gray-700">
      <div className="bg-blue-800 text-white px-5 py-4 flex justify-between items-center">
        <h3 className="text-lg font-semibold m-0">AI Decision Reasoning</h3>
        <span className="text-sm opacity-80">{decision?.timestamp}</span>
      </div>
      <div className="p-5">
        <div className="mb-5">
          <h4 className="text-base font-semibold mb-2 text-gray-200">Why this allocation?</h4>
          <p className="text-gray-300 leading-relaxed">{decision?.reasoning || 'No reasoning provided'}</p>
        </div>
        <div className="mb-5">
          <h4 className="text-base font-semibold mb-2 text-gray-200">Current Allocation</h4>
          <ul className="list-none p-0">
            {decision?.strategies.map((strategy, index) => (
              <li key={strategy} className="flex justify-between py-2 border-b border-gray-700">
                <span className="font-mono text-gray-400">{`${strategy.slice(0, 6)}...${strategy.slice(-4)}`}</span>
                <span className="font-semibold text-blue-400">{decision.allocations[index]}</span>
              </li>
            ))}
          </ul>
        </div>
        <div>
          <h4 className="text-base font-semibold mb-2 text-gray-200">Verification</h4>
          <p className="text-sm text-gray-400">Decision ID: {decision?.id}</p>
          <p className="text-sm text-gray-400 mb-3">Signature: {decision?.signature}</p>
          <a href={`/verify?id=${decision?.id}&signature=${decision?.signature}`} className="inline-block bg-blue-700 hover:bg-blue-800 text-white font-semibold py-2 px-4 rounded transition-colors border border-blue-600 shadow-lg">
            Verify Decision
          </a>
        </div>
      </div>
    </div>
  );
};

export default MCPDecisionCard;
