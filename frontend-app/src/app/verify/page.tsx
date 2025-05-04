'use client';

import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import MCPVerification from '@/components/mcp/MCPVerification';

export default function VerifyPage() {
  const searchParams = useSearchParams();
  const [decisionId, setDecisionId] = useState<string | null>(null);
  const [signature, setSignature] = useState<string | null>(null);
  
  useEffect(() => {
    const id = searchParams.get('id');
    const sig = searchParams.get('signature');
    
    if (id) setDecisionId(id);
    if (sig) setSignature(sig);
  }, [searchParams]);

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-4">MCP Decision Verification</h1>
        <p className="text-gray-600">
          Verify the authenticity of AI-driven allocation decisions using the Model Context Protocol.
        </p>
      </div>

      {decisionId && signature ? (
        <MCPVerification 
          decisionId={decisionId} 
          signature={signature} 
        />
      ) : (
        <div className="bg-white rounded-xl shadow-md overflow-hidden">
          <div className="bg-blue-600 text-white px-5 py-4">
            <h3 className="text-lg font-semibold">Verify Decision</h3>
          </div>
          <div className="p-5">
            <p className="text-gray-600 mb-6">
              Enter the Decision ID and Signature to verify the authenticity of an AI allocation decision.
            </p>
            
            <form className="space-y-4">
              <div>
                <label htmlFor="decisionId" className="block text-sm font-medium text-gray-700 mb-1">
                  Decision ID
                </label>
                <input
                  type="text"
                  id="decisionId"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  placeholder="0x1234..."
                  value={decisionId || ''}
                  onChange={(e) => setDecisionId(e.target.value)}
                />
              </div>
              
              <div>
                <label htmlFor="signature" className="block text-sm font-medium text-gray-700 mb-1">
                  Signature
                </label>
                <input
                  type="text"
                  id="signature"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  placeholder="0xabcd..."
                  value={signature || ''}
                  onChange={(e) => setSignature(e.target.value)}
                />
              </div>
              
              <button
                type="button"
                className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded transition-colors"
                onClick={() => {
                  // Update URL with parameters
                  if (decisionId && signature) {
                    const url = new URL(window.location.href);
                    url.searchParams.set('id', decisionId);
                    url.searchParams.set('signature', signature);
                    window.history.pushState({}, '', url);
                  }
                }}
              >
                Verify Decision
              </button>
            </form>
          </div>
        </div>
      )}
      
      <div className="mt-8 bg-gray-50 rounded-lg p-6">
        <h2 className="text-lg font-semibold text-gray-800 mb-4">About MCP Verification</h2>
        <p className="text-gray-600 mb-4">
          The Model Context Protocol (MCP) ensures transparency and verifiability in AI-driven decision making.
          Each allocation decision made by NapFi AI is recorded on-chain with a cryptographic signature that
          can be verified to ensure the decision was made by the authorized AI system and has not been tampered with.
        </p>
        <p className="text-gray-600">
          By verifying decisions, users can trust that their funds are being allocated based on legitimate
          AI recommendations and not manipulated by malicious actors.
        </p>
      </div>
    </div>
  );
}
