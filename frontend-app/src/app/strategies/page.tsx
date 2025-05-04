'use client';

import { NavbarSpacer } from '@/components/Navbar';
import React, { useState } from 'react';

const StrategyCard = ({ name, description, apy, risk, tvl }: {
  name: string;
  description: string;
  apy: string;
  risk: string;
  tvl: string;
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
        <button className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded transition-colors shadow-lg">
          Allocate Funds
        </button>
      </div>
    </div>
    </>
  );
};

export default function StrategiesPage() {
  // Mock data for strategies
  const strategies = [
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
    {
      id: '4',
      name: 'Convex Boosted Pools',
      description: 'Stake in Convex Finance to maximize CRV yields with boosted rewards.',
      apy: '8.2%',
      risk: 'Medium',
      tvl: '$320M',
    },
    {
      id: '5',
      name: 'Yearn Vaults',
      description: 'Deposit into Yearn vaults for automated yield optimization strategies.',
      apy: '7.1%',
      risk: 'Medium',
      tvl: '$580M',
    },
    {
      id: '6',
      name: 'Balancer Pools',
      description: 'Provide liquidity to Balancer pools to earn trading fees and BAL rewards.',
      apy: '5.9%',
      risk: 'Medium',
      tvl: '$210M',
    },
  ];

  const [activeTab, setActiveTab] = useState('all');

  const filteredStrategies = activeTab === 'all' 
    ? strategies 
    : strategies.filter(s => {
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
          />
        ))}
      </div>
    </div>
    </>
  );
}
