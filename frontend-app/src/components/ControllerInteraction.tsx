import React, { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, useConfig } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { CONTRACT_ADDRESSES } from '@/config/web3';
import { testControllerABI } from '../abis/testControllerABI';
import { testStrategyABI } from '../abis/testStrategyABI';
import { testTokenABI } from '../abis/testTokenABI';
import { testVaultABI } from '../abis/testVaultABI';

// Tooltip component for better user guidance
const Tooltip = ({ text, children }: { text: string; children: React.ReactNode }) => {
  const [isVisible, setIsVisible] = useState(false);
  
  return (
    <div className="relative inline-block">
      <div 
        onMouseEnter={() => setIsVisible(true)}
        onMouseLeave={() => setIsVisible(false)}
        className="inline-flex items-center"
      >
        {children}
        <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 ml-1 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      {isVisible && (
        <div className="absolute z-10 w-64 p-2 mt-1 text-sm text-white bg-gray-800 rounded-md shadow-lg">
          {text}
        </div>
      )}
    </div>
  );
};

// Notification component for success/error messages
const Notification = ({ type, message, onClose }: { type: 'success' | 'error'; message: string; onClose: () => void }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, 5000);
    
    return () => clearTimeout(timer);
  }, [onClose]);
  
  return (
    <div className={`fixed top-4 right-4 p-4 rounded-md shadow-lg ${type === 'success' ? 'bg-green-500' : 'bg-red-500'} text-white`}>
      <div className="flex items-center">
        {type === 'success' ? (
          <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
        ) : (
          <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        )}
        <p>{message}</p>
        <button onClick={onClose} className="ml-4">
          <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>
  );
};

// Simple chart component to visualize APY
const APYChart = ({ apy }: { apy: number }) => {
  // Calculate the width based on APY (max 100%)
  const width = Math.min(apy * 10, 100);
  
  return (
    <div className="mt-4">
      <div className="flex justify-between mb-1">
        <span className="text-sm font-medium text-gray-300">APY Performance</span>
        <span className="text-sm font-medium text-gray-300">{apy}%</span>
      </div>
      <div className="w-full bg-gray-700 rounded-full h-2.5">
        <div 
          className="bg-blue-600 h-2.5 rounded-full" 
          style={{ width: `${width}%` }}
        ></div>
      </div>
      <div className="flex justify-between text-xs text-gray-400 mt-1">
        <span>0%</span>
        <span>5%</span>
        <span>10%</span>
      </div>
    </div>
  );
};

// Portfolio value visualization
const PortfolioValue = ({ vaultBalance, strategyBalance }: { vaultBalance: string; strategyBalance: string }) => {
  const vaultValue = parseFloat(vaultBalance);
  const strategyValue = parseFloat(strategyBalance);
  const total = vaultValue + strategyValue;
  
  // Calculate percentages
  const vaultPercentage = total > 0 ? (vaultValue / total) * 100 : 0;
  const strategyPercentage = total > 0 ? (strategyValue / total) * 100 : 0;
  
  return (
    <div className="mt-6">
      <h3 className="text-lg font-semibold mb-2 text-white">Portfolio Allocation</h3>
      <div className="w-full bg-gray-700 rounded-full h-4 mb-2">
        <div 
          className="bg-blue-600 h-4 rounded-l-full" 
          style={{ width: `${vaultPercentage}%` }}
        ></div>
      </div>
      <div className="flex justify-between text-sm text-gray-300">
        <div className="flex items-center">
          <div className="w-3 h-3 rounded-full bg-blue-600 mr-2"></div>
          <span>Vault: {vaultValue.toFixed(2)} TEST ({vaultPercentage.toFixed(0)}%)</span>
        </div>
        <div className="flex items-center">
          <div className="w-3 h-3 rounded-full bg-purple-600 mr-2"></div>
          <span>Strategy: {strategyValue.toFixed(2)} TEST ({strategyPercentage.toFixed(0)}%)</span>
        </div>
      </div>
    </div>
  );
};

export default function ControllerInteraction() {
  const config = useConfig();
  const { address, isConnected, chainId } = useAccount();
  const { writeContractAsync } = useWriteContract();
  
  // State variables
  const [controllerBalance, setControllerBalance] = useState<string>('0');
  const [strategyBalance, setStrategyBalance] = useState<string>('0');
  const [vaultBalance, setVaultBalance] = useState<string>('0');
  const [strategyCount, setStrategyCount] = useState<number>(0);
  const [strategyAPY, setStrategyAPY] = useState<string>('0');
  const [depositAmount, setDepositAmount] = useState<string>('10');
  const [txHash, setTxHash] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<'deposit' | 'yield' | 'withdraw'>('deposit');
  const [notification, setNotification] = useState<{type: 'success' | 'error'; message: string} | null>(null);
  const [simulatedYield, setSimulatedYield] = useState<number[]>([5, 5.2, 5.4, 5.3, 5.5, 5.7, 5.9, 6.1, 6.0, 6.2, 6.5, 6.8]);
  const [withdrawAmount, setWithdrawAmount] = useState<string>('5');
  
  // Get the appropriate contract addresses based on the current chain
  const networkKey = chainId === 11155111 ? 'sepolia' : 'local';
  const testControllerAddress = CONTRACT_ADDRESSES[networkKey].testController;
  const testStrategyAddress = CONTRACT_ADDRESSES[networkKey].testStrategy;
  const testTokenAddress = CONTRACT_ADDRESSES[networkKey].testToken;
  const testVaultAddress = CONTRACT_ADDRESSES[networkKey].vault;
  
  // Read vault balance
  const { data: vaultBalanceData, refetch: refetchVaultBalance } = useReadContract({
    address: testVaultAddress as `0x${string}`,
    abi: testTokenABI,
    functionName: 'balanceOf',
    args: [testVaultAddress],
  });

  // Read controller balance
  const { data: controllerBalanceData, refetch: refetchControllerBalance } = useReadContract({
    address: testControllerAddress as `0x${string}`,
    abi: testControllerABI,
    functionName: 'getControllerBalance',
  });
  
  // Read strategy balance
  const { data: strategyBalanceData, refetch: refetchStrategyBalance } = useReadContract({
    address: testStrategyAddress as `0x${string}`,
    abi: testStrategyABI,
    functionName: 'getStrategyBalance',
  });
  
  // Read strategy count
  const { data: strategyCountData, refetch: refetchStrategyCount } = useReadContract({
    address: testControllerAddress as `0x${string}`,
    abi: testControllerABI,
    functionName: 'getStrategyCount',
  });
  
  // Read strategy APY
  const { data: strategyAPYData, refetch: refetchStrategyAPY } = useReadContract({
    address: testStrategyAddress as `0x${string}`,
    abi: testStrategyABI,
    functionName: 'apy',
  });
  
  // Read user token balance
  const { data: userBalanceData, refetch: refetchUserBalance } = useReadContract({
    address: testTokenAddress as `0x${string}`,
    abi: testTokenABI,
    functionName: 'balanceOf',
    args: [address],
  });
  
  // Wait for transaction receipt
  const { isLoading: isWaiting, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash: txHash as `0x${string}`,
  });
  
  // Update state when data changes
  useEffect(() => {
    if (controllerBalanceData) {
      setControllerBalance(formatEther(controllerBalanceData as bigint));
    }
    if (strategyBalanceData) {
      setStrategyBalance(formatEther(strategyBalanceData as bigint));
    }
    if (vaultBalanceData) {
      setVaultBalance(formatEther(vaultBalanceData as bigint));
    }
    if (strategyCountData) {
      setStrategyCount(Number(strategyCountData));
    }
    if (strategyAPYData) {
      setStrategyAPY(((Number(strategyAPYData) / 100).toString()));
    }
  }, [controllerBalanceData, strategyBalanceData, vaultBalanceData, strategyCountData, strategyAPYData]);
  
  // Refetch data when transaction is confirmed
  useEffect(() => {
    if (isConfirmed) {
      // Show success notification
      setNotification({
        type: 'success',
        message: 'Transaction confirmed successfully!'
      });
      
      // Refetch all data
      refetchControllerBalance();
      refetchStrategyBalance();
      refetchVaultBalance();
      refetchStrategyCount();
      refetchStrategyAPY();
      if (address) refetchUserBalance();
      
      setIsLoading(false);
    }
  }, [isConfirmed, refetchControllerBalance, refetchStrategyBalance, refetchVaultBalance, refetchStrategyCount, refetchStrategyAPY, refetchUserBalance, address]);
  
  // Clear notification after display
  const clearNotification = () => {
    setNotification(null);
  };
  
  // Approve tokens for the vault
  const handleApprove = async () => {
    if (!isConnected || !address) return;
    
    try {
      setIsLoading(true);
      const hash = await writeContractAsync({
        address: testTokenAddress as `0x${string}`,
        abi: testTokenABI,
        functionName: 'approve',
        args: [testVaultAddress, parseEther(depositAmount)],
      });
      setTxHash(hash);
    } catch (error) {
      console.error('Error approving tokens:', error);
      setIsLoading(false);
    }
  };
  
  // Deposit to vault
  const handleDeposit = async () => {
    if (!isConnected || !address) return;
    
    try {
      setIsLoading(true);
      const hash = await writeContractAsync({
        address: testVaultAddress as `0x${string}`,
        abi: testVaultABI,
        functionName: 'deposit',
        args: [parseEther(depositAmount)],
      });
      setTxHash(hash);
    } catch (error) {
      console.error('Error depositing to vault:', error);
      setIsLoading(false);
    }
  };
  
  // Generate yield
  const handleGenerateYield = async () => {
    if (!isConnected || !address) return;
    
    try {
      setIsLoading(true);
      const hash = await writeContractAsync({
        address: testStrategyAddress as `0x${string}`,
        abi: testStrategyABI,
        functionName: 'generateYield',
        args: [],
      });
      setTxHash(hash);
    } catch (error) {
      console.error('Error generating yield:', error);
      setNotification({
        type: 'error',
        message: 'Failed to generate yield. Please try again.'
      });
      setIsLoading(false);
    }
  };
  
  // Withdraw from vault
  const handleWithdraw = async () => {
    if (!isConnected || !address) return;
    
    try {
      setIsLoading(true);
      const hash = await writeContractAsync({
        address: testVaultAddress as `0x${string}`,
        abi: testVaultABI,
        functionName: 'withdraw',
        args: [parseEther(withdrawAmount)],
      });
      setTxHash(hash);
    } catch (error) {
      console.error('Error withdrawing from vault:', error);
      setNotification({
        type: 'error',
        message: 'Failed to withdraw. Please try again.'
      });
      setIsLoading(false);
    }
  };
  
  // Handle tab change
  const handleTabChange = (tab: 'deposit' | 'yield' | 'withdraw') => {
    setActiveTab(tab);
  };
  
  return (
    <div className="bg-gray-800 shadow-lg rounded-lg p-6 mb-6 border border-gray-700">
      {/* Header with title and description */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold mb-2 text-white">NapFi AI Controller</h2>
        <p className="text-gray-300">Interact with the NapFi AI yield optimization system</p>
      </div>
      
      {/* Portfolio Overview */}
      <div className="bg-gradient-to-r from-gray-900 to-blue-900 p-6 rounded-lg mb-6 border border-gray-700">
        <h3 className="text-xl font-semibold mb-4 text-white">Portfolio Overview</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <div className="bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-700">
            <h4 className="text-sm font-medium text-gray-400 mb-1">Total Value</h4>
            <p className="text-2xl font-bold text-white">
              {(parseFloat(controllerBalance) + parseFloat(strategyBalance) + parseFloat(vaultBalance)).toFixed(2)} TEST
            </p>
          </div>
          
          <div className="bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-700">
            <Tooltip text="Annual Percentage Yield - The estimated yearly return on your investment">
              <h4 className="text-sm font-medium text-gray-400 mb-1">Current APY</h4>
            </Tooltip>
            <p className="text-2xl font-bold text-green-400">{strategyAPY}%</p>
            <APYChart apy={parseFloat(strategyAPY)} />
          </div>
          
          <div className="bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-700">
            <h4 className="text-sm font-medium text-gray-400 mb-1">Active Strategies</h4>
            <p className="text-2xl font-bold text-white">{strategyCount}</p>
          </div>
        </div>
        
        {/* Portfolio Allocation Chart */}
        <PortfolioValue vaultBalance={vaultBalance} strategyBalance={strategyBalance} />
      </div>
      
      {/* AI Decision Visualization */}
      <div className="bg-gray-800 border border-gray-700 rounded-lg p-6 mb-6 shadow-lg">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-xl font-semibold text-white">AI Decision Module</h3>
          <span className="px-2 py-1 bg-green-900 text-green-300 text-xs font-medium rounded border border-green-700">Active</span>
        </div>
        
        <div className="mb-4">
          <div className="flex justify-between mb-1">
            <span className="text-sm font-medium text-gray-300">Market Volatility Assessment</span>
            <span className="text-sm font-medium text-gray-300">Medium</span>
          </div>
          <div className="w-full bg-gray-700 rounded-full h-2.5">
            <div className="bg-yellow-500 h-2.5 rounded-full" style={{ width: '60%' }}></div>
          </div>
        </div>
        
        <div className="mb-4">
          <div className="flex justify-between mb-1">
            <span className="text-sm font-medium text-gray-300">Risk Tolerance</span>
            <span className="text-sm font-medium text-gray-300">Balanced</span>
          </div>
          <div className="w-full bg-gray-700 rounded-full h-2.5">
            <div className="bg-blue-500 h-2.5 rounded-full" style={{ width: '50%' }}></div>
          </div>
        </div>
        
        <div className="mb-4">
          <div className="flex justify-between mb-1">
            <span className="text-sm font-medium text-gray-300">Yield Opportunity</span>
            <span className="text-sm font-medium text-gray-300">High</span>
          </div>
          <div className="w-full bg-gray-700 rounded-full h-2.5">
            <div className="bg-green-500 h-2.5 rounded-full" style={{ width: '80%' }}></div>
          </div>
        </div>
        
        <div className="p-4 bg-gray-900 rounded-lg border border-gray-700">
          <h4 className="font-medium mb-2 text-white">Latest AI Recommendation</h4>
          <p className="text-gray-300">Based on current market conditions, the AI recommends maintaining the current allocation with a slight increase in exposure to higher yield opportunities.</p>
        </div>
      </div>
      
      {/* Action Tabs */}
      <div className="bg-gray-800 border border-gray-700 rounded-lg overflow-hidden mb-6 shadow-lg">
        <div className="flex border-b border-gray-700">
          <button
            onClick={() => handleTabChange('deposit')}
            className={`flex-1 py-3 px-4 text-center font-medium ${activeTab === 'deposit' ? 'bg-blue-900 text-blue-300 border-b-2 border-blue-500' : 'text-gray-300 hover:text-gray-100'}`}
          >
            Deposit
          </button>
          <button
            onClick={() => handleTabChange('yield')}
            className={`flex-1 py-3 px-4 text-center font-medium ${activeTab === 'yield' ? 'bg-blue-900 text-blue-300 border-b-2 border-blue-500' : 'text-gray-300 hover:text-gray-100'}`}
          >
            Generate Yield
          </button>
          <button
            onClick={() => handleTabChange('withdraw')}
            className={`flex-1 py-3 px-4 text-center font-medium ${activeTab === 'withdraw' ? 'bg-blue-900 text-blue-300 border-b-2 border-blue-500' : 'text-gray-300 hover:text-gray-100'}`}
          >
            Withdraw
          </button>
        </div>
        
        <div className="p-6">
          {activeTab === 'deposit' && (
            <div>
              <h3 className="text-lg font-semibold mb-4 text-white">Deposit Funds</h3>
              <div className="flex items-center space-x-2 mb-4">
                <input
                  type="number"
                  value={depositAmount}
                  onChange={(e) => setDepositAmount(e.target.value)}
                  className="bg-gray-700 border border-gray-600 text-white rounded p-2 w-full md:w-64 focus:border-blue-500 focus:ring-blue-500"
                  min="0"
                  step="0.1"
                  placeholder="Amount to deposit"
                />
                <span className="font-medium text-gray-300">TEST</span>
              </div>
              
              <div className="flex space-x-3">
                <button
                  onClick={handleApprove}
                  disabled={isLoading || !isConnected}
                  className="bg-blue-700 hover:bg-blue-800 text-white px-6 py-2 rounded-md disabled:bg-gray-700 disabled:text-gray-400 disabled:cursor-not-allowed flex items-center shadow-lg border border-blue-600"
                >
                  {isLoading && txHash ? (
                    <>
                      <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Approving...
                    </>
                  ) : 'Approve'}
                </button>
                
                <button
                  onClick={handleDeposit}
                  disabled={isLoading || !isConnected}
                  className="bg-green-700 hover:bg-green-800 text-white px-6 py-2 rounded-md disabled:bg-gray-700 disabled:text-gray-400 disabled:cursor-not-allowed flex items-center shadow-lg border border-green-600"
                >
                  {isLoading && txHash ? (
                    <>
                      <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Depositing...
                    </>
                  ) : 'Deposit'}
                </button>
              </div>
            </div>
          )}
          
          {activeTab === 'yield' && (
            <div>
              <h3 className="text-lg font-semibold mb-4 text-white">Generate Yield</h3>
              <p className="text-gray-300 mb-4">
                This simulates the yield generation process for testing purposes. In a real-world scenario, 
                yield would be generated automatically by the strategy's investments.
              </p>
              
              <button
                onClick={handleGenerateYield}
                disabled={isLoading || !isConnected}
                className="bg-purple-700 hover:bg-purple-800 text-white px-6 py-2 rounded-md disabled:bg-gray-700 disabled:text-gray-400 disabled:cursor-not-allowed flex items-center shadow-lg border border-purple-600"
              >
                {isLoading && txHash ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Generating...
                  </>
                ) : 'Generate Yield'}
              </button>
            </div>
          )}
          
          {activeTab === 'withdraw' && (
            <div>
              <h3 className="text-lg font-semibold mb-4 text-white">Withdraw Funds</h3>
              <div className="flex items-center space-x-2 mb-4">
                <input
                  type="number"
                  value={withdrawAmount}
                  onChange={(e) => setWithdrawAmount(e.target.value)}
                  className="bg-gray-700 border border-gray-600 text-white rounded p-2 w-full md:w-64 focus:border-blue-500 focus:ring-blue-500"
                  min="0"
                  step="0.1"
                  placeholder="Amount to withdraw"
                />
                <span className="font-medium text-gray-300">TEST</span>
              </div>
              
              <button
                onClick={handleWithdraw}
                disabled={isLoading || !isConnected}
                className="bg-red-700 hover:bg-red-800 text-white px-6 py-2 rounded-md disabled:bg-gray-700 disabled:text-gray-400 disabled:cursor-not-allowed flex items-center shadow-lg border border-red-600"
              >
                {isLoading && txHash ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Withdrawing...
                  </>
                ) : 'Withdraw'}
              </button>
            </div>
          )}
        </div>
      </div>
      
      {/* Contract Info */}
      <div className="bg-gray-800 border border-gray-700 rounded-lg p-6 mb-6 shadow-lg">
        <h3 className="text-lg font-semibold mb-4 text-white">Contract Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="text-sm font-medium text-gray-400 mb-1">Controller</h4>
            <p className="font-mono text-xs break-all text-gray-300">{testControllerAddress}</p>
            <p className="mt-1 text-gray-300">Balance: {controllerBalance} TEST</p>
          </div>
          
          <div>
            <h4 className="text-sm font-medium text-gray-400 mb-1">Strategy</h4>
            <p className="font-mono text-xs break-all text-gray-300">{testStrategyAddress}</p>
            <p className="mt-1 text-gray-300">Balance: {strategyBalance} TEST</p>
          </div>
        </div>
      </div>
      
      {/* Transaction Status */}
      {txHash && (
        <div className="bg-gray-800 border border-gray-700 rounded-lg p-6 shadow-lg">
          <h3 className="text-lg font-semibold mb-4 text-white">Transaction Status</h3>
          <div className="flex items-center mb-4">
            <div className={`w-3 h-3 rounded-full mr-2 ${isWaiting ? 'bg-yellow-400' : isConfirmed ? 'bg-green-500' : 'bg-blue-500'}`}></div>
            <span className="font-medium text-gray-300">{isWaiting ? 'Processing...' : isConfirmed ? 'Confirmed' : 'Pending'}</span>
          </div>
          
          <div className="bg-gray-900 p-4 rounded-lg border border-gray-700">
            <p className="text-sm text-gray-400 mb-2">Transaction Hash:</p>
            <a 
              href={`https://sepolia.etherscan.io/tx/${txHash}`} 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-blue-400 hover:text-blue-300 hover:underline break-all font-mono text-xs"
            >
              {txHash}
            </a>
          </div>
        </div>
      )}
      
      {/* Notification */}
      {notification && (
        <Notification 
          type={notification.type} 
          message={notification.message} 
          onClose={clearNotification} 
        />
      )}
    </div>
  );
}
