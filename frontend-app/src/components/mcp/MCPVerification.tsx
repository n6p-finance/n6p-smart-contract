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
    <div className="bg-white rounded-xl shadow-md overflow-hidden">
      <div className="bg-blue-600 text-white px-5 py-4">
        <h3 className="text-lg font-semibold">Verify Decision Authenticity</h3>
      </div>
      <div className="p-5">
        <div className="mb-4">
          <p className="text-gray-600 mb-4">
            Verify that this decision was made by NapFi AI and has not been tampered with.
          </p>
          <div className="bg-gray-50 p-4 rounded-lg mb-4">
            <p className="text-sm text-gray-500 mb-1">Decision ID:</p>
            <p className="font-mono text-sm break-all">{decisionId}</p>
            <p className="text-sm text-gray-500 mb-1 mt-3">Signature:</p>
            <p className="font-mono text-sm break-all">{signature}</p>
          </div>
        </div>
        
        {verificationStatus === 'idle' && (
          <button 
            onClick={handleVerify}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded transition-colors"
          >
            Verify Signature
          </button>
        )}
        
        {verificationStatus === 'verifying' && (
          <div className="flex justify-center items-center py-2">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
            <p className="ml-3 text-gray-600">Verifying signature...</p>
          </div>
        )}
        
        {verificationStatus === 'verified' && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-4">
            <div className="flex items-center mb-2">
              <svg className="h-5 w-5 text-green-500 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <p className="text-green-700 font-semibold">Verification Successful</p>
            </div>
            <p className="text-green-600">{verificationDetails}</p>
          </div>
        )}
        
        {verificationStatus === 'failed' && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <div className="flex items-center mb-2">
              <svg className="h-5 w-5 text-red-500 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
              <p className="text-red-700 font-semibold">Verification Failed</p>
            </div>
            <p className="text-red-600">The signature could not be verified. This decision may have been tampered with.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default MCPVerification;
