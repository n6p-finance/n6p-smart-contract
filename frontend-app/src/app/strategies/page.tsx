'use client';

import { NavbarSpacer } from '@/components/Navbar';
import { CONTRACT_ADDRESSES } from '@/config/web3';
import React, { useState } from 'react';

const StrategyCard = ({ name, description, apy, risk, tvl, address }: {
  name: string;
  description: string;
  apy: string;
  risk: string;
  tvl: string;
  address?: string;
}) => {
  return (
    <>
    <div className="bg-gray-800 rounded-xl shadow-md overflow-hidden transition-all hover:shadow-lg border border-gray-700">
      <div className="bg-indigo-800 text-white px-5 py-4">
        <h3 className="text-lg font-semibold">{name}</h3>
      </div>
      <div className="p-5">
        <p className="text-gray-300 mb-4">{description}</p>
        <div className="grid grid-cols-3 gap-4 mb-4">
          <div className="text-center">
            <p className="text-sm text-gray-400">APY</p>
            <p className="text-lg font-semibold text-indigo-400">{apy}</p>
          </div>
          <div className="text-center">
            <p className="text-sm text-gray-400">Risk</p>
            <p className="text-lg font-semibold text-indigo-400">{risk}</p>
          </div>
          <div className="text-center">
            <p className="text-sm text-gray-400">TVL</p>
            <p className="text-lg font-semibold text-indigo-400">{tvl}</p>
          </div>
        </div>
        {address && (
          <div className="mb-4 px-3 py-2 bg-gray-900 rounded-md">
            <p className="text-xs text-gray-400 break-all">Contract: {address}</p>
          </div>
        )}
        <button className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded transition-colors shadow-lg">
          Allocate Funds
        </button>
      </div>
    </div>
    </>
  );
};

export default function StrategiesPage() {
  // Deployed strategies with actual contract addresses
  const deployedStrategies = [
    {
      id: 'deployed-1',
      name: 'NapFi Balanced Strategy',
      description: 'Our standard yield strategy with balanced risk-reward profile. Deployed on Sepolia testnet.',
      apy: '5.0%',
      risk: 'Medium',
      tvl: '$1.5M',
      address: CONTRACT_ADDRESSES.sepolia.testStrategy,
      deployed: true
    },
    {
      id: 'deployed-2',
      name: 'NapFi High-Yield Strategy',
      description: 'Higher risk strategy targeting maximum returns. Recently deployed on Sepolia testnet.',
      apy: '8.0%',
      risk: 'High',
      tvl: '$750K',
      address: CONTRACT_ADDRESSES.sepolia.highYieldStrategy,
      deployed: true
    },
    {
      id: 'deployed-3',
      name: 'NapFi Stable-Yield Strategy',
      description: 'Conservative strategy focused on capital preservation with steady returns. Recently deployed on Sepolia testnet.',
      apy: '3.0%',
      risk: 'Low',
      tvl: '$2.2M',
      address: CONTRACT_ADDRESSES.sepolia.stableYieldStrategy,
      deployed: true
    },
  ];
  
  // Additional strategy examples for demo purposes
  const additionalStrategies = [
    {
      id: '1',
      name: 'Aave Lending',
      description: 'Deposit assets into Aave lending pools to earn interest from borrowers.',
      apy: '4.2%',
      risk: 'Low',
      tvl: '$1.2B',
    },
    {
      id: '2',
      name: 'Compound Lending',
      description: 'Provide liquidity to Compound protocol to earn interest and COMP tokens.',
      apy: '3.8%',
      risk: 'Low',
      tvl: '$890M',
    },
    {
      id: '3',
      name: 'Curve Liquidity',
      description: 'Supply liquidity to Curve stablecoin pools to earn trading fees and CRV rewards.',
      apy: '6.5%',
      risk: 'Medium',
      tvl: '$450M',
    },
  ];
  
  // Define the strategy type to include the optional address property
  type Strategy = {
    id: string;
    name: string;
    description: string;
    apy: string;
    risk: string;
    tvl: string;
    address?: string;
    deployed?: boolean;
  };
  
  // Combine all strategies
  const strategies: Strategy[] = [...deployedStrategies, ...additionalStrategies];

  const [activeTab, setActiveTab] = useState('all');

  const filteredStrategies = activeTab === 'all' 
    ? strategies 
    : strategies.filter((s: Strategy) => {
        if (activeTab === 'low') return s.risk === 'Low';
        if (activeTab === 'medium') return s.risk === 'Medium';
        if (activeTab === 'high') return s.risk === 'High';
        return true;
      });

  return (
    <>
    <NavbarSpacer />
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white mb-4">AI-Optimized Strategies</h1>
        <p className="text-gray-300">
          Our AI continuously analyzes market conditions to allocate funds optimally across these strategies.
        </p>
        <div className="mt-4 p-4 bg-blue-900/30 border border-blue-800 rounded-lg">
          <h2 className="text-lg font-semibold text-blue-300 mb-2">Hackathon Demo</h2>
          <p className="text-gray-300 text-sm">
            The top three strategies are actually deployed on Sepolia testnet with different APY profiles (8%, 5%, and 3%).
            These demonstrate how NapFi AI can allocate funds across multiple yield strategies based on risk preferences.
          </p>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex border-b border-gray-700 mb-6">
        <button
          onClick={() => setActiveTab('all')}
          className={`px-4 py-2 font-medium text-sm ${activeTab === 'all' ? 'border-b-2 border-indigo-400 text-indigo-400' : 'text-gray-400 hover:text-gray-200'}`}
        >
          All Strategies
        </button>
        <button
          onClick={() => setActiveTab('low')}
          className={`px-4 py-2 font-medium text-sm ${activeTab === 'low' ? 'border-b-2 border-indigo-400 text-indigo-400' : 'text-gray-400 hover:text-gray-200'}`}
        >
          Low Risk
        </button>
        <button
          onClick={() => setActiveTab('medium')}
          className={`px-4 py-2 font-medium text-sm ${activeTab === 'medium' ? 'border-b-2 border-indigo-400 text-indigo-400' : 'text-gray-400 hover:text-gray-200'}`}
        >
          Medium Risk
        </button>
        <button
          onClick={() => setActiveTab('high')}
          className={`px-4 py-2 font-medium text-sm ${activeTab === 'high' ? 'border-b-2 border-indigo-400 text-indigo-400' : 'text-gray-400 hover:text-gray-200'}`}
        >
          High Risk
        </button>
      </div>

      {/* Strategy cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredStrategies.map(strategy => (
          <StrategyCard
            key={strategy.id}
            name={strategy.name}
            description={strategy.description}
            apy={strategy.apy}
            risk={strategy.risk}
            tvl={strategy.tvl}
            address={strategy.address}
          />
        ))}
      </div>
    </div>
    </>
  );
}
