'use client';

import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import MCPDecisionCard from '@/components/mcp/MCPDecisionCard';
import MCPVerification from '@/components/mcp/MCPVerification';

export default function DecisionsPage() {
  const searchParams = useSearchParams();
  
  // Mock data for decisions
  const decisions = [
    {
      id: '0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234',
      date: 'May 1, 2025',
      title: 'Initial allocation',
      signature: '0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef'
    },
    {
      id: '0x234567890abcdef234567890abcdef234567890abcdef234567890abcdef2345',
      date: 'May 15, 2025',
      title: 'Rebalance due to market change',
      signature: '0xbcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab'
    },
    {
      id: '0x345678901abcdef345678901abcdef345678901abcdef345678901abcdef3456',
      date: 'June 1, 2025',
      title: 'Added new strategy',
      signature: '0xcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abc'
    },
  ];

  // Get decision ID from URL or use first decision as default
  const [selectedDecision, setSelectedDecision] = useState<string | null>(null);
  
  useEffect(() => {
    const idFromUrl = searchParams.get('id');
    if (idFromUrl) {
      setSelectedDecision(idFromUrl);
    } else {
      setSelectedDecision(decisions[0].id);
    }
  }, [searchParams]);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-4">AI Decision History</h1>
        <p className="text-gray-600">
          View the history of allocation decisions made by NapFi AI and understand the reasoning behind each decision.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-1">
          <div className="bg-white rounded-xl shadow-md overflow-hidden">
            <div className="bg-blue-600 text-white px-5 py-4">
              <h3 className="text-lg font-semibold">Decision History</h3>
            </div>
            <div className="p-0">
              <ul className="divide-y divide-gray-200">
                {decisions.map((decision) => (
                  <li key={decision.id} className="cursor-pointer">
                    <button
                      className={`w-full text-left py-4 px-5 transition-colors ${
                        selectedDecision === decision.id
                          ? 'bg-blue-50'
                          : 'hover:bg-gray-50'
                      }`}
                      onClick={() => setSelectedDecision(decision.id)}
                    >
                      <span className="text-sm text-gray-500 block">{decision.date}</span>
                      <span className={`${
                        selectedDecision === decision.id
                          ? 'text-blue-700 font-medium'
                          : 'text-gray-800'
                      }`}>
                        {decision.title}
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        <div className="lg:col-span-2 space-y-6">
          {selectedDecision && (
            <>
              <MCPDecisionCard decisionId={selectedDecision} />
              
              {/* Find the selected decision to get its signature */}
              {decisions.find(d => d.id === selectedDecision) && (
                <MCPVerification 
                  decisionId={selectedDecision} 
                  signature={decisions.find(d => d.id === selectedDecision)?.signature || ''} 
                />
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
