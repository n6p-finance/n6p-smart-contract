'use client';

import React, { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useReadContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther, parseUnits, formatUnits } from 'viem';
import { CONTRACT_ADDRESSES } from '@/config/web3';
import VaultABI from '@/abi/Vault.json';
import TokenApproval from './TokenApproval';

/**
 * Component for interacting with the Vault contract (deposits and withdrawals)
 */
const VaultInteraction: React.FC = () => {
  const { address, isConnected } = useAccount();
  const [amount, setAmount] = useState<string>('');
  const [isDeposit, setIsDeposit] = useState<boolean>(true);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'deposit' | 'withdraw' | 'stats'>('deposit');
  const [showAPYHistory, setShowAPYHistory] = useState<boolean>(false);

  // Use the vault address from our contract addresses configuration
  const vaultAddress = CONTRACT_ADDRESSES.vault;
  
  // TestToken address from our contract addresses configuration
  const tokenAddress = CONTRACT_ADDRESSES.testToken;
  
  // State to track if approval is needed
  const [needsApproval, setNeedsApproval] = useState<boolean>(true);
  
  // Token details
  const [tokenSymbol, setTokenSymbol] = useState<string>('NAPTEST');
  const [tokenDecimals, setTokenDecimals] = useState<number>(18);
  
  // Mock historical data for APY chart
  const [apyHistory] = useState<{date: string; apy: number}[]>([
    { date: 'Apr 1', apy: 4.2 },
    { date: 'Apr 8', apy: 4.5 },
    { date: 'Apr 15', apy: 4.8 },
    { date: 'Apr 22', apy: 5.1 },
    { date: 'Apr 29', apy: 5.3 },
    { date: 'May 1', apy: 5.2 },
  ]);
  
  // Mock total value locked history
  const [tvlHistory] = useState<{date: string; value: number}[]>([
    { date: 'Apr 1', value: 850000 },
    { date: 'Apr 8', value: 920000 },
    { date: 'Apr 15', value: 980000 },
    { date: 'Apr 22', value: 1050000 },
    { date: 'Apr 29', value: 1120000 },
    { date: 'May 1', value: 1200000 },
  ]);

  // Read user's share balance
  const { data: userShares } = useReadContract({
    address: vaultAddress as `0x${string}`,
    abi: VaultABI,
    functionName: 'balanceOf',
    args: [address as `0x${string}`],
    query: {
      enabled: Boolean(isConnected && address),
    }
  });

  // Read price per share
  const { data: pricePerShare } = useReadContract({
    address: vaultAddress as `0x${string}`,
    abi: VaultABI,
    functionName: 'getPricePerShare',
    query: {
      enabled: Boolean(isConnected),
    }
  });

  // Read total assets in vault
  const { data: totalAssets } = useReadContract({
    address: vaultAddress as `0x${string}`,
    abi: VaultABI,
    functionName: 'totalAssets',
  });
  
  // Read price per share
  const { data: pricePerFullShare } = useReadContract({
    address: vaultAddress as `0x${string}`,
    abi: VaultABI,
    functionName: 'getPricePerShare',
  });
  
  // Read token balance of user
  const { data: userTokenBalance, refetch: refetchUserTokenBalance } = useReadContract({
    address: tokenAddress as `0x${string}`,
    abi: VaultABI,
    functionName: 'balanceOf',
    args: [address as `0x${string}`],
  });

  // Write contract function for deposit/withdraw
  const { writeContractAsync, isPending } = useWriteContract();
  
  // Wait for transaction receipt
  const { isLoading: isWaiting, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash: txHash as `0x${string}`,
  });
  
  // Update UI after transaction confirmation
  useEffect(() => {
    if (isConfirmed && txHash) {
      // Show success message
      setSuccess(isDeposit ? 'Deposit successful!' : 'Withdrawal successful!');
      
      // Clear form
      setAmount('');
      
      // Reset transaction hash after a delay
      setTimeout(() => {
        setTxHash(null);
        setSuccess(null);
      }, 5000);
    }
  }, [isConfirmed, txHash, isDeposit]);

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setTxHash(null);

    if (!amount || parseFloat(amount) <= 0) {
      setError('Please enter a valid amount');
      return;
    }

    try {
      // Parse amount with proper decimals
      const parsedAmount = parseUnits(amount, tokenDecimals);
      
      // Call the appropriate function based on the action (deposit or withdraw)
      const hash = await writeContractAsync({
        address: vaultAddress as `0x${string}`,
        abi: VaultABI,
        functionName: activeTab === 'deposit' ? 'deposit' : 'withdraw',
        args: [parsedAmount],
      });
      
      setTxHash(hash);
    } catch (err: any) {
      console.error('Transaction error:', err);
      setError(err.message || 'Transaction failed');
    }
  };
  
  // Format numbers for display
  const formatLargeNumber = (num: number): string => {
    if (num >= 1000000) {
      return `$${(num / 1000000).toFixed(2)}M`;
    } else if (num >= 1000) {
      return `$${(num / 1000).toFixed(2)}K`;
    } else {
      return `$${num.toFixed(2)}`;
    }
  };
  
  // Calculate APY (mock for demo)
  const calculateAPY = (): number => {
    return apyHistory[apyHistory.length - 1].apy;
  };

  // Format user's share balance for display
  const formattedShares = userShares ? formatUnits(userShares as bigint, tokenDecimals) : '0';
  
  // Calculate estimated value based on shares and price per share
  const estimatedValue = userShares && pricePerShare
    ? formatUnits((userShares as bigint) * (pricePerShare as bigint) / BigInt(10**tokenDecimals), tokenDecimals)
    : '0';

  // Handle approval completion
  const handleApprovalComplete = () => {
    setNeedsApproval(false);
  };
  
  return (
    <div className="rounded-xl shadow-md p-6 mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-white">NapFi AI Vault</h2>
        <div className="flex space-x-2">
          <div className="bg-green-900 text-green-300 px-3 py-1 rounded-full text-sm font-medium flex items-center border border-green-700">
            <span className="w-2 h-2 bg-green-400 rounded-full mr-2"></span>
            Active
          </div>
          <div className="bg-blue-900 text-blue-300 px-3 py-1 rounded-full text-sm font-medium border border-blue-700">
            APY: {calculateAPY()}%
          </div>
        </div>
      </div>
      
      {/* Main content with tabs */}
      <div className="mb-8">
        <div className="border-b border-gray-700">
          <nav className="-mb-px flex space-x-8" aria-label="Tabs">
            <button
              onClick={() => setActiveTab('deposit')}
              className={`${activeTab === 'deposit' ? 'border-blue-500 text-blue-400' : 'border-transparent text-gray-400 hover:text-gray-200 hover:border-gray-600'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
            >
              Deposit
            </button>
            <button
              onClick={() => setActiveTab('withdraw')}
              className={`${activeTab === 'withdraw' ? 'border-blue-500 text-blue-400' : 'border-transparent text-gray-400 hover:text-gray-200 hover:border-gray-600'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
            >
              Withdraw
            </button>
            <button
              onClick={() => setActiveTab('stats')}
              className={`${activeTab === 'stats' ? 'border-blue-500 text-blue-400' : 'border-transparent text-gray-400 hover:text-gray-200 hover:border-gray-600'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
            >
              Vault Stats
            </button>
          </nav>
        </div>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left panel - Form */}
        <div className="lg:col-span-2">
          {activeTab === 'stats' ? (
            <div className="bg-gray-800 rounded-lg border border-gray-700 p-4">
              <h3 className="text-lg font-semibold mb-4 text-white">Vault Performance</h3>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                <div className="bg-gray-900 p-4 rounded-lg border border-gray-700">
                  <h4 className="text-sm text-gray-400 mb-1">Total Value Locked</h4>
                  <p className="text-2xl font-bold text-white">{formatLargeNumber(tvlHistory[tvlHistory.length - 1].value)}</p>
                  <p className="text-sm text-green-400 mt-1">+{((tvlHistory[tvlHistory.length - 1].value - tvlHistory[tvlHistory.length - 2].value) / tvlHistory[tvlHistory.length - 2].value * 100).toFixed(1)}% from last week</p>
                </div>
                
                <div className="bg-gray-900 p-4 rounded-lg border border-gray-700">
                  <h4 className="text-sm text-gray-400 mb-1">Current APY</h4>
                  <p className="text-2xl font-bold text-white">{calculateAPY()}%</p>
                  <p className="text-sm text-green-400 mt-1">+{(apyHistory[apyHistory.length - 1].apy - apyHistory[apyHistory.length - 2].apy).toFixed(1)}% from last week</p>
                </div>
                
                <div className="bg-gray-900 p-4 rounded-lg border border-gray-700">
                  <h4 className="text-sm text-gray-400 mb-1">Price Per Share</h4>
                  <p className="text-2xl font-bold text-white">{pricePerFullShare ? formatUnits(pricePerFullShare as bigint, tokenDecimals) : '0'}</p>
                  <p className="text-sm text-blue-400 mt-1">Increases with yield</p>
                </div>
              </div>
              
              <div className="mb-8">
                <div className="flex justify-between items-center mb-4">
                  <h4 className="font-medium text-white">APY History</h4>
                  <button 
                    onClick={() => setShowAPYHistory(!showAPYHistory)}
                    className="text-sm text-blue-400 hover:text-blue-300"
                  >
                    {showAPYHistory ? 'Hide' : 'Show'} Details
                  </button>
                </div>
                
                <div className="bg-gray-800 p-4 rounded-lg border border-gray-700 shadow-lg">
                  {/* Simple chart visualization */}
                  <div className="h-40 flex items-end space-x-2">
                    {apyHistory.map((item, index) => (
                      <div key={index} className="flex-1 flex flex-col items-center">
                        <div 
                          className="w-full bg-blue-600 rounded-t" 
                          style={{ height: `${(item.apy / 10) * 100}%` }}
                        ></div>
                        {showAPYHistory && (
                          <div className="text-xs mt-2 text-gray-400">{item.date}</div>
                        )}
                      </div>
                    ))}
                  </div>
                  
                  {showAPYHistory && (
                    <div className="mt-4">
                      <table className="min-w-full divide-y divide-gray-700">
                        <thead>
                          <tr>
                            <th className="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
                            <th className="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">APY</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-700">
                          {apyHistory.map((item, index) => (
                            <tr key={index}>
                              <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-400">{item.date}</td>
                              <td className="px-3 py-2 whitespace-nowrap text-sm font-medium text-blue-400">{item.apy}%</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              </div>
              
              <div>
                <h4 className="font-medium mb-4 text-white">Vault Strategy</h4>
                <div className="bg-gray-900 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-300 mb-3">
                    This vault uses NapFi AI to optimize yield by dynamically allocating funds across multiple strategies based on market conditions and risk parameters.
                  </p>
                  <div className="flex items-center space-x-2 text-sm text-gray-400">
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                    </svg>
                    <span>Managed by NapFi AI Decision Module</span>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="bg-gray-800 rounded-lg border border-gray-700 p-4">
              <h3 className="text-lg font-semibold mb-4 text-white">
                {activeTab === 'deposit' ? 'Deposit to Vault' : 'Withdraw from Vault'}
              </h3>
              
              {/* Show token approval component if needed */}
              {activeTab === 'deposit' && needsApproval && (
                <div className="mb-6">
                  <TokenApproval 
                    tokenAddress={tokenAddress}
                    spenderAddress={vaultAddress}
                    onApprovalComplete={handleApprovalComplete}
                  />
                </div>
              )}
              
              {/* Form */}
              <form onSubmit={handleSubmit} className="bg-gray-900 p-6 rounded-lg border border-gray-700">
                <div className="mb-6">
                  <label htmlFor="amount" className="block text-sm font-medium text-gray-300 mb-2">
                    Amount ({tokenSymbol})
                  </label>
                  <div className="relative rounded-md shadow-sm">
                    <input
                      type="number"
                      id="amount"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      placeholder="0.0"
                      step="0.01"
                      min="0"
                      className="block w-full rounded-md bg-gray-800 border-gray-700 text-white pr-20 focus:border-blue-500 focus:ring-blue-500 py-3 px-4"
                      disabled={!isConnected || isPending || isWaiting}
                    />
                    <div className="absolute inset-y-0 right-0 flex items-center">
                      <button
                        type="button"
                        className="inline-flex items-center rounded-r-md border border-gray-600 bg-gray-700 px-4 py-2 text-sm font-medium text-blue-300 hover:bg-gray-600 focus:outline-none transition-colors"
                        onClick={() => {
                          // Set max amount based on balance
                          if (activeTab === 'deposit' && userTokenBalance) {
                            setAmount(formatUnits(userTokenBalance as bigint, tokenDecimals));
                          } else if (activeTab === 'withdraw' && userShares) {
                            setAmount(formatUnits(userShares as bigint, tokenDecimals));
                          }
                        }}
                      >
                        MAX
                      </button>
                    </div>
                  </div>
                  
                  {/* Balance info */}
                  <div className="mt-2 flex justify-between text-sm text-gray-400">
                    <span>Available: </span>
                    <span>
                      {activeTab === 'deposit' && userTokenBalance
                        ? `${formatUnits(userTokenBalance as bigint, tokenDecimals)} ${tokenSymbol}`
                        : activeTab === 'withdraw' && userShares
                        ? `${formatUnits(userShares as bigint, tokenDecimals)} shares`
                        : '0'}
                    </span>
                  </div>
                </div>
                
                <div className="flex flex-col space-y-4">
                  <button
                    type="submit"
                    className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded-md transition-colors disabled:bg-gray-700 disabled:text-gray-400 disabled:cursor-not-allowed flex justify-center items-center shadow-lg"
                    disabled={!isConnected || isPending || isWaiting || !amount}
                  >
                    {isPending || isWaiting ? (
                      <>
                        <svg className="animate-spin -ml-1 mr-2 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        {isPending ? 'Processing...' : 'Confirming...'}
                      </>
                    ) : (
                      activeTab === 'deposit' ? 'Deposit to Vault' : 'Withdraw from Vault'
                    )}
                  </button>
                  
                  {activeTab === 'deposit' && (
                    <div className="text-sm text-gray-600 bg-blue-50 p-3 rounded-md">
                      <p>When you deposit, you receive vault shares proportional to the current price per share. As the vault generates yield, your shares become worth more.</p>
                    </div>
                  )}
                  
                  {activeTab === 'withdraw' && (
                    <div className="text-sm text-gray-600 bg-blue-50 p-3 rounded-md">
                      <p>When you withdraw, your shares are burned and you receive the corresponding amount of tokens plus any yield generated.</p>
                    </div>
                  )}
                </div>
              </form>
              
              {/* Transaction status */}
              {txHash && (
                <div className="mt-6 p-4 bg-white border border-gray-200 rounded-lg shadow-sm">
                  <div className="flex items-center mb-2">
                    <div className={`w-3 h-3 rounded-full mr-2 ${isWaiting ? 'bg-yellow-400' : isConfirmed ? 'bg-green-500' : 'bg-blue-500'}`}></div>
                    <h4 className="font-medium">Transaction {isWaiting ? 'Processing' : isConfirmed ? 'Confirmed' : 'Submitted'}</h4>
                  </div>
                  <p className="text-sm text-gray-600 mb-2">
                    Transaction Hash: 
                  </p>
                  <a
                    href={`https://sepolia.etherscan.io/tx/${txHash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:text-blue-800 text-sm font-mono break-all"
                  >
                    {txHash}
                  </a>
                </div>
              )}
              
              {/* Success message */}
              {success && (
                <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-md">
                  <div className="flex">
                    <svg className="h-5 w-5 text-green-400 mr-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                    <p className="text-green-800">{success}</p>
                  </div>
                </div>
              )}
              
              {/* Error message */}
              {error && (
                <div className="mt-4 p-4 bg-red-900 border border-red-700 rounded-md">
                  <div className="flex">
                    <svg className="h-5 w-5 text-red-400 mr-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                    </svg>
                    <p className="text-red-300">{error}</p>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
        
        {/* Right panel - Portfolio & Info */}
        <div>
          <div className="bg-gradient-to-br from-blue-900 to-indigo-900 rounded-lg p-6 mb-6 border border-blue-700 shadow-lg">
            <h3 className="text-lg font-semibold mb-4 text-white">Your Portfolio</h3>
            
            <div className="mb-4">
              <div className="flex justify-between text-sm text-gray-300 mb-1">
                <span>Your Shares:</span>
                <span>{formattedShares}</span>
              </div>
              <div className="w-full bg-gray-700 rounded-full h-2">
                <div 
                  className="bg-blue-500 h-2 rounded-full" 
                  style={{ width: `${parseFloat(formattedShares) > 0 ? '100' : '0'}%` }}
                ></div>
              </div>
            </div>
            
            <div className="mb-6">
              <div className="flex justify-between text-sm text-gray-300 mb-1">
                <span>Estimated Value:</span>
                <span>{estimatedValue} {tokenSymbol}</span>
              </div>
              <div className="w-full bg-gray-700 rounded-full h-2">
                <div 
                  className="bg-green-500 h-2 rounded-full" 
                  style={{ width: `${parseFloat(estimatedValue) > 0 ? '100' : '0'}%` }}
                ></div>
              </div>
            </div>
            
            <div className="bg-gray-800 rounded-md p-4 border border-gray-700">
              <div className="flex justify-between items-center">
                <span className="text-gray-300">Current APY:</span>
                <span className="text-lg font-bold text-green-400">{calculateAPY()}%</span>
              </div>
              <div className="mt-2 text-xs text-gray-400">
                APY is variable and based on market conditions
              </div>
            </div>
          </div>
          
          <div className="bg-gray-800 border border-gray-700 rounded-lg p-6 shadow-lg">
            <h3 className="text-lg font-semibold mb-4 text-white">How It Works</h3>
            
            <div className="space-y-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <div className="flex items-center justify-center h-8 w-8 rounded-full bg-blue-900 text-blue-300 border border-blue-700">
                    1
                  </div>
                </div>
                <div className="ml-4">
                  <h4 className="text-sm font-medium text-gray-200">Deposit</h4>
                  <p className="text-sm text-gray-400">Deposit your tokens into the vault and receive shares</p>
                </div>
              </div>
              
              <div className="flex">
                <div className="flex-shrink-0">
                  <div className="flex items-center justify-center h-8 w-8 rounded-full bg-blue-900 text-blue-300 border border-blue-700">
                    2
                  </div>
                </div>
                <div className="ml-4">
                  <h4 className="text-sm font-medium text-gray-200">AI Optimization</h4>
                  <p className="text-sm text-gray-400">NapFi AI allocates funds to optimal yield strategies</p>
                </div>
              </div>
              
              <div className="flex">
                <div className="flex-shrink-0">
                  <div className="flex items-center justify-center h-8 w-8 rounded-full bg-blue-900 text-blue-300 border border-blue-700">
                    3
                  </div>
                </div>
                <div className="ml-4">
                  <h4 className="text-sm font-medium text-gray-200">Earn Yield</h4>
                  <p className="text-sm text-gray-400">Your share value increases as the vault generates yield</p>
                </div>
              </div>
              
              <div className="flex">
                <div className="flex-shrink-0">
                  <div className="flex items-center justify-center h-8 w-8 rounded-full bg-blue-900 text-blue-300 border border-blue-700">
                    4
                  </div>
                </div>
                <div className="ml-4">
                  <h4 className="text-sm font-medium text-gray-200">Withdraw</h4>
                  <p className="text-sm text-gray-400">Withdraw your tokens plus yield at any time</p>
                </div>
              </div>
            </div>
          </div>
          
          {/* Note for demo */}
          <div className="mt-6 bg-yellow-50 p-4 rounded-lg border border-yellow-200">
            <div className="flex">
              <svg className="h-5 w-5 text-yellow-400 mr-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
              </svg>
              <p className="text-sm text-yellow-800">
                <strong>Note:</strong> This is connected to the Sepolia testnet. Make sure your wallet has some NAPTEST tokens.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VaultInteraction;
