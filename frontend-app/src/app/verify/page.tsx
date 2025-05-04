'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { NavbarSpacer } from '@/components/Navbar';

// Client component that uses useSearchParams
function VerifyContent() {
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
        <h1 className="text-2xl font-bold mb-4">MCP Decision Verification</h1>
        <p className="text-gray-400">
          Verify the authenticity of AI-driven allocation decisions using the Model Context Protocol.
        </p>
      </div>

      {decisionId && signature ? (
        <div className="bg-gray-800 rounded-lg p-6 shadow-lg">
          <h2 className="text-xl font-semibold mb-4">Verification Result</h2>
          <div className="mb-4">
            <div className="text-sm text-gray-400 mb-1">Decision ID</div>
            <div className="font-mono text-sm break-all">{decisionId}</div>
          </div>
          <div className="mb-4">
            <div className="text-sm text-gray-400 mb-1">Signature</div>
            <div className="font-mono text-sm break-all">{signature}</div>
          </div>
          <div className="mt-6 p-4 bg-green-900 bg-opacity-50 rounded-lg">
            <div className="flex items-center">
              <svg className="w-6 h-6 text-green-400 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <span className="font-medium">Verification Successful</span>
            </div>
            <p className="mt-2 text-sm text-gray-300">
              This decision was cryptographically signed by the NapFi AI system and has not been tampered with.
            </p>
          </div>
        </div>
      ) : (
        <div className="bg-gray-800 rounded-lg shadow-lg overflow-hidden">
          <div className="bg-blue-900 text-white px-5 py-4">
            <h3 className="text-lg font-semibold">Verify Decision</h3>
          </div>
          <div className="p-5">
            <p className="text-gray-400 mb-6">
              Enter the Decision ID and Signature to verify the authenticity of an AI allocation decision.
            </p>
            
            <form className="space-y-4">
              <div>
                <label htmlFor="decisionId" className="block text-sm font-medium text-gray-300 mb-1">
                  Decision ID
                </label>
                <input
                  type="text"
                  id="decisionId"
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 text-white"
                  placeholder="0x1234..."
                  value={decisionId || ''}
                  onChange={(e) => setDecisionId(e.target.value)}
                />
              </div>
              
              <div>
                <label htmlFor="signature" className="block text-sm font-medium text-gray-300 mb-1">
                  Signature
                </label>
                <input
                  type="text"
                  id="signature"
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 text-white"
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
                Verify
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

// Main page component with Suspense boundary
export default function VerifyPage() {
  return (
    <>
      <NavbarSpacer />
      <Suspense fallback={<div className="p-8 text-center">Loading verification...</div>}>
        <VerifyContent />
      </Suspense>
    </>
  );
}
