'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import MCPDecisionCard from '@/components/mcp/MCPDecisionCard';
import MCPVerification from '@/components/mcp/MCPVerification';
import AIDecisionVisualization from '@/components/AIDecisionVisualization';
import { NavbarSpacer } from '@/components/Navbar';

// Define the decision type
type Decision = {
  id: string;
  date: string;
  title: string;
  signature: string;
};

// Create a client component that uses useSearchParams
function DecisionsContent() {
  const searchParams = useSearchParams();
  
  // Mock data for decisions
  const decisions: Decision[] = [
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
    } else if (decisions.length > 0) {
      setSelectedDecision(decisions[0].id);
    }
  }, [searchParams]);
  
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-4">AI Decisions</h1>
        <p className="text-gray-400">
          NapFi AI makes allocation decisions based on market conditions, risk factors, and yield opportunities.
          Each decision is cryptographically signed and can be verified on-chain.
        </p>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-1">
          <div className="bg-gray-800 rounded-lg p-6 shadow-lg">
            <h2 className="text-xl font-semibold mb-4">Decision History</h2>
            <div className="space-y-4">
              {decisions.map((decision) => (
                <div 
                  key={decision.id}
                  className={`p-4 rounded-lg cursor-pointer ${decision.id === selectedDecision ? 'bg-blue-900' : 'bg-gray-700'}`}
                  onClick={() => setSelectedDecision(decision.id)}
                >
                  <div className="text-sm text-gray-400">{decision.date}</div>
                  <div className="font-medium">{decision.title}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
        
        <div className="lg:col-span-2">
          {selectedDecision && (
            <div className="space-y-8">
              <div className="bg-gray-800 rounded-lg p-6 shadow-lg">
                <h2 className="text-xl font-semibold mb-4">AI Decision Details</h2>
                <div className="mb-4">
                  <div className="text-sm text-gray-400 mb-1">Decision ID</div>
                  <div className="font-mono text-sm break-all">{selectedDecision}</div>
                </div>
                <div className="mb-4">
                  <div className="text-sm text-gray-400 mb-1">Signature</div>
                  <div className="font-mono text-sm break-all">
                    {decisions.find(d => d.id === selectedDecision)?.signature || ''}
                  </div>
                </div>
                <div className="mt-6">
                  <h3 className="text-lg font-medium mb-2">Allocation Strategy</h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="bg-gray-700 p-4 rounded-lg">
                      <div className="text-sm text-gray-400 mb-1">Strategy 1</div>
                      <div className="font-medium">60%</div>
                    </div>
                    <div className="bg-gray-700 p-4 rounded-lg">
                      <div className="text-sm text-gray-400 mb-1">Strategy 2</div>
                      <div className="font-medium">30%</div>
                    </div>
                    <div className="bg-gray-700 p-4 rounded-lg">
                      <div className="text-sm text-gray-400 mb-1">Strategy 3</div>
                      <div className="font-medium">10%</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Main page component with Suspense boundary
export default function DecisionsPage() {
  return (
    <>
      <NavbarSpacer />
      <Suspense fallback={<div className="p-8 text-center">Loading decisions...</div>}>
        <DecisionsContent />
      </Suspense>
    </>
  );
}
