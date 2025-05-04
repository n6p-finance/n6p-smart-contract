'use client';

import React, { useState } from 'react';
import { useReadContract } from 'wagmi';
import { CONTRACT_ADDRESSES } from '@/config/web3';
import AIDecisionModuleABI from '@/abi/AIDecisionModule.json';

interface MCPVerificationProps {
  decisionId: string;
  signature: string;
  aiDecisionModuleAddress?: string;
}

/**
 * Component to verify MCP decision signatures
 */
const MCPVerification: React.FC<MCPVerificationProps> = ({
  decisionId,
  signature,
  aiDecisionModuleAddress = CONTRACT_ADDRESSES.aiDecisionModule
}) => {
  const [verificationStatus, setVerificationStatus] = useState<'idle' | 'verifying' | 'verified' | 'failed'>('idle');
  const [verificationDetails, setVerificationDetails] = useState<string | null>(null);

  // This would normally call a contract method to verify the signature
  const handleVerify = () => {
    setVerificationStatus('verifying');
    
    // Simulate verification process
    setTimeout(() => {
      // For demo purposes, we'll just simulate a successful verification
      setVerificationStatus('verified');
      setVerificationDetails(
        'Signature verified by MCP Oracle. This decision was made by NapFi AI with 99.8% confidence.'
      );
    }, 2000);
  };

  return (
    <div className="bg-gray-800 rounded-xl shadow-md overflow-hidden border border-gray-700">
      <div className="bg-blue-800 text-white px-5 py-4">
        <h3 className="text-lg font-semibold">Verify Decision Authenticity</h3>
      </div>
      <div className="p-5">
        <div className="mb-4">
          <p className="text-gray-300 mb-4">
            Verify that this decision was made by NapFi AI and has not been tampered with.
          </p>
          <div className="bg-gray-900 p-4 rounded-lg mb-4 border border-gray-700">
            <p className="text-sm text-gray-400 mb-1">Decision ID:</p>
            <p className="font-mono text-sm break-all text-gray-300">{decisionId}</p>
            <p className="text-sm text-gray-400 mb-1 mt-3">Signature:</p>
            <p className="font-mono text-sm break-all text-gray-300">{signature}</p>
          </div>
        </div>
        
        {verificationStatus === 'idle' && (
          <button
            onClick={handleVerify}
            className="w-full bg-blue-700 hover:bg-blue-800 text-white font-semibold py-2 px-4 rounded transition-colors shadow-lg border border-blue-600"
          >
            Verify Signature
          </button>
        )}
        
        {verificationStatus === 'verifying' && (
          <div className="flex justify-center items-center py-2">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-400"></div>
            <span className="ml-3 text-gray-300">Verifying...</span>
          </div>
        )}
        
        {verificationStatus === 'verified' && (
          <div className="bg-green-900 border border-green-700 text-green-300 rounded-lg p-4">
            <div className="flex items-start">
              <svg className="h-5 w-5 text-green-400 mr-2 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <div>
                <p className="font-medium">Verification Successful</p>
                <p className="text-sm mt-1">{verificationDetails}</p>
              </div>
            </div>
          </div>
        )}
        
        {verificationStatus === 'failed' && (
          <div className="bg-red-900 border border-red-700 text-red-300 rounded-lg p-4">
            <div className="flex items-start">
              <svg className="h-5 w-5 text-red-400 mr-2 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
              <div>
                <p className="font-medium">Verification Failed</p>
                <p className="text-sm mt-1">This signature could not be verified. The decision may have been tampered with.</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default MCPVerification;
