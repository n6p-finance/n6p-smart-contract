'use client';

import React, { useState } from 'react';

const StrategyCard = ({ name, description, apy, risk, tvl }: {
  name: string;
  description: string;
  apy: string;
  risk: string;
  tvl: string;
}) => {
  return (
    <div className="bg-white rounded-xl shadow-md overflow-hidden transition-all hover:shadow-lg">
      <div className="bg-indigo-600 text-white px-5 py-4">
        <h3 className="text-lg font-semibold">{name}</h3>
      </div>
      <div className="p-5">
        <p className="text-gray-600 mb-4">{description}</p>
        <div className="grid grid-cols-3 gap-4 mb-4">
          <div className="text-center">
            <p className="text-sm text-gray-500">APY</p>
            <p className="text-lg font-semibold text-indigo-600">{apy}</p>
          </div>
          <div className="text-center">
            <p className="text-sm text-gray-500">Risk</p>
            <p className="text-lg font-semibold text-indigo-600">{risk}</p>
          </div>
          <div className="text-center">
            <p className="text-sm text-gray-500">TVL</p>
            <p className="text-lg font-semibold text-indigo-600">{tvl}</p>
          </div>
        </div>
        <button className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded transition-colors">
          Allocate Funds
        </button>
      </div>
    </div>
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
      description: 'Supply assets to Compound protocol to earn interest and COMP tokens.',
      apy: '3.8%',
      risk: 'Low',
      tvl: '$890M',
    },
    {
      id: '3',
      name: 'Curve Stablecoin LP',
      description: 'Provide liquidity to Curve stablecoin pools and earn trading fees.',
      apy: '5.1%',
      risk: 'Medium',
      tvl: '$450M',
    },
    {
      id: '4',
      name: 'Uniswap V3 LP',
      description: 'Provide concentrated liquidity to Uniswap V3 pools.',
      apy: '8.5%',
      risk: 'Medium-High',
      tvl: '$320M',
    },
    {
      id: '5',
      name: 'Lido Staking',
      description: 'Stake ETH with Lido to earn staking rewards while maintaining liquidity.',
      apy: '3.9%',
      risk: 'Low',
      tvl: '$2.1B',
    },
    {
      id: '6',
      name: 'Yearn Vaults',
      description: 'Deposit into Yearn vaults for automated yield optimization.',
      apy: '6.7%',
      risk: 'Medium',
      tvl: '$580M',
    },
  ];

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-4">Available Strategies</h1>
        <p className="text-gray-600">
          NapFi AI automatically allocates your funds across these strategies based on market conditions, risk profile, and yield opportunities.
        </p>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {strategies.map((strategy) => (
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
  );
}
