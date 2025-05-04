import React, { useState, useEffect } from 'react';
import { formatEther } from 'viem';

// Types for market data
interface MarketData {
  assetName: string;
  price: number;
  change24h: number;
  volatility: number;
  volume: number;
  marketCap: number;
  yield: number;
}

// Types for strategy data
interface StrategyData {
  id: number;
  name: string;
  description: string;
  apy: number;
  risk: number;
  allocation: number;
  tvl: number;
}

// Types for AI decision
interface AIDecision {
  timestamp: string;
  marketSentiment: 'bullish' | 'bearish' | 'neutral';
  riskScore: number;
  confidenceScore: number;
  recommendedStrategies: number[];
  reasoning: string;
}

interface AIDecisionSimulationProps {
  controllerBalance?: string;
  strategyBalance?: string;
  strategyAPY?: string;
  onAllocationChange?: (strategyId: number, allocation: number) => void;
}

const AIDecisionSimulation: React.FC<AIDecisionSimulationProps> = ({
  controllerBalance = '0',
  strategyBalance = '0',
  strategyAPY = '0',
  onAllocationChange
}) => {
  // Mock market data
  const [marketData, setMarketData] = useState<MarketData[]>([
    { assetName: 'ETH', price: 3245.67, change24h: 2.3, volatility: 0.65, volume: 12500000000, marketCap: 389000000000, yield: 4.2 },
    { assetName: 'BTC', price: 48750.32, change24h: -1.2, volatility: 0.58, volume: 28700000000, marketCap: 920000000000, yield: 3.1 },
    { assetName: 'USDC', price: 1.00, change24h: 0.01, volatility: 0.02, volume: 5600000000, marketCap: 32000000000, yield: 5.8 },
    { assetName: 'DAI', price: 1.00, change24h: 0.02, volatility: 0.03, volume: 1200000000, marketCap: 5600000000, yield: 6.1 },
  ]);

  // Mock strategy data
  const [strategies, setStrategies] = useState<StrategyData[]>([
    { id: 1, name: 'Conservative Yield', description: 'Low risk, stable yield from stablecoin lending', apy: 5.2, risk: 2, allocation: 40, tvl: 1200000 },
    { id: 2, name: 'Balanced Growth', description: 'Medium risk, diversified across lending and liquidity pools', apy: 8.7, risk: 5, allocation: 35, tvl: 3500000 },
    { id: 3, name: 'Aggressive Growth', description: 'Higher risk, leveraged yield farming strategies', apy: 15.3, risk: 8, allocation: 25, tvl: 900000 },
  ]);

  // Mock AI decisions
  const [aiDecisions, setAiDecisions] = useState<AIDecision[]>([
    {
      timestamp: '2025-05-04T12:00:00Z',
      marketSentiment: 'neutral',
      riskScore: 5.2,
      confidenceScore: 0.78,
      recommendedStrategies: [1, 2],
      reasoning: 'Market conditions show moderate volatility with stable yields in stablecoin markets. A balanced approach is recommended.'
    }
  ]);

  // Current AI decision
  const [currentDecision, setCurrentDecision] = useState<AIDecision>(aiDecisions[0]);
  
  // Simulation state
  const [isSimulating, setIsSimulating] = useState(false);
  const [simulationStep, setSimulationStep] = useState(0);
  const [simulationSpeed, setSimulationSpeed] = useState(2000); // ms between updates
  
  // Market indicators
  const [marketIndicators, setMarketIndicators] = useState({
    volatility: 45, // 0-100 scale
    opportunity: 62, // 0-100 scale
    liquidity: 78, // 0-100 scale
    sentiment: 'neutral' as 'bullish' | 'bearish' | 'neutral'
  });

  // Calculate total portfolio value
  const totalValue = parseFloat(controllerBalance) + parseFloat(strategyBalance);
  
  // Format large numbers
  const formatNumber = (num: number): string => {
    if (num >= 1000000000) {
      return `$${(num / 1000000000).toFixed(1)}B`;
    } else if (num >= 1000000) {
      return `$${(num / 1000000).toFixed(1)}M`;
    } else if (num >= 1000) {
      return `$${(num / 1000).toFixed(1)}K`;
    } else {
      return `$${num.toFixed(2)}`;
    }
  };

  // Generate a new AI decision
  const generateNewDecision = () => {
    // Randomly adjust market indicators
    const newVolatility = Math.max(10, Math.min(90, marketIndicators.volatility + (Math.random() * 20 - 10)));
    const newOpportunity = Math.max(10, Math.min(90, marketIndicators.opportunity + (Math.random() * 20 - 10)));
    const newLiquidity = Math.max(10, Math.min(90, marketIndicators.liquidity + (Math.random() * 15 - 7.5)));
    
    // Determine sentiment based on indicators
    let newSentiment: 'bullish' | 'bearish' | 'neutral';
    if (newOpportunity > 65 && newVolatility < 50) {
      newSentiment = 'bullish';
    } else if (newOpportunity < 40 || newVolatility > 70) {
      newSentiment = 'bearish';
    } else {
      newSentiment = 'neutral';
    }
    
    // Update market indicators
    setMarketIndicators({
      volatility: newVolatility,
      opportunity: newOpportunity,
      liquidity: newLiquidity,
      sentiment: newSentiment
    });
    
    // Calculate risk score based on indicators
    const riskScore = (newVolatility / 20) + ((100 - newLiquidity) / 20);
    
    // Determine recommended strategies based on risk score and opportunity
    let recommendedStrategies: number[] = [];
    if (riskScore < 4) {
      recommendedStrategies = [1]; // Conservative only
    } else if (riskScore < 7) {
      recommendedStrategies = [1, 2]; // Conservative and Balanced
    } else {
      recommendedStrategies = [2, 3]; // Balanced and Aggressive
    }
    
    // If opportunity is high, add aggressive strategy
    if (newOpportunity > 75 && !recommendedStrategies.includes(3)) {
      recommendedStrategies.push(3);
    }
    
    // Generate reasoning text
    let reasoning = '';
    if (newSentiment === 'bullish') {
      reasoning = 'Market conditions are favorable with low volatility and high yield opportunities. Increasing allocation to higher yield strategies is recommended.';
    } else if (newSentiment === 'bearish') {
      reasoning = 'Market conditions show increased volatility and reduced yield opportunities. A more conservative approach is recommended to preserve capital.';
    } else {
      reasoning = 'Market conditions are stable with moderate volatility. A balanced approach is recommended with diversification across risk profiles.';
    }
    
    // Create new decision
    const newDecision: AIDecision = {
      timestamp: new Date().toISOString(),
      marketSentiment: newSentiment,
      riskScore: parseFloat(riskScore.toFixed(1)),
      confidenceScore: parseFloat((0.5 + Math.random() * 0.4).toFixed(2)),
      recommendedStrategies,
      reasoning
    };
    
    // Update decisions array and current decision
    setAiDecisions(prev => [...prev, newDecision]);
    setCurrentDecision(newDecision);
    
    // Update strategy allocations based on AI recommendation
    const newStrategies = [...strategies];
    
    // Reset allocations to minimum values
    newStrategies.forEach(s => {
      s.allocation = 10; // Minimum 10% allocation
    });
    
    // Distribute remaining 70% based on recommendations
    const remainingAllocation = 70;
    const recommendedCount = recommendedStrategies.length;
    
    if (recommendedCount > 0) {
      const baseAllocation = remainingAllocation / recommendedCount;
      
      recommendedStrategies.forEach(stratId => {
        const stratIndex = newStrategies.findIndex(s => s.id === stratId);
        if (stratIndex !== -1) {
          newStrategies[stratIndex].allocation += baseAllocation;
        }
      });
    }
    
    // Ensure allocations sum to 100%
    const totalAllocation = newStrategies.reduce((sum, s) => sum + s.allocation, 0);
    if (totalAllocation !== 100) {
      const adjustment = (100 - totalAllocation) / newStrategies.length;
      newStrategies.forEach(s => {
        s.allocation += adjustment;
        s.allocation = parseFloat(s.allocation.toFixed(1));
      });
    }
    
    setStrategies(newStrategies);
    
    // Notify parent component of allocation changes
    if (onAllocationChange) {
      newStrategies.forEach(s => {
        onAllocationChange(s.id, s.allocation);
      });
    }
  };

  // Start/stop simulation
  const toggleSimulation = () => {
    setIsSimulating(!isSimulating);
  };

  // Run simulation
  useEffect(() => {
    let simulationTimer: NodeJS.Timeout;
    
    if (isSimulating) {
      simulationTimer = setInterval(() => {
        setSimulationStep(prev => prev + 1);
        generateNewDecision();
      }, simulationSpeed);
    }
    
    return () => {
      if (simulationTimer) clearInterval(simulationTimer);
    };
  }, [isSimulating, simulationSpeed]);

  // Render sentiment indicator
  const renderSentimentIndicator = (sentiment: 'bullish' | 'bearish' | 'neutral') => {
    let color = '';
    let icon = '';
    
    switch (sentiment) {
      case 'bullish':
        color = 'text-green-600';
        icon = '↑';
        break;
      case 'bearish':
        color = 'text-red-600';
        icon = '↓';
        break;
      default:
        color = 'text-yellow-600';
        icon = '→';
    }
    
    return (
      <span className={`inline-flex items-center ${color} font-medium`}>
        {sentiment.charAt(0).toUpperCase() + sentiment.slice(1)} {icon}
      </span>
    );
  };

  return (
    <div className="bg-gray-900 shadow-xl rounded-lg p-6 mb-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-white">AI Decision Module</h2>
        <div className="flex items-center space-x-3">
          <div className="flex items-center">
            <label htmlFor="simulation-speed" className="text-sm text-gray-300 mr-2">Speed:</label>
            <select 
              id="simulation-speed"
              value={simulationSpeed}
              onChange={(e) => setSimulationSpeed(parseInt(e.target.value))}
              className="bg-gray-800 border border-gray-700 rounded p-1 text-sm text-gray-200"
              disabled={isSimulating}
            >
              <option value="4000">Slow</option>
              <option value="2000">Normal</option>
              <option value="1000">Fast</option>
            </select>
          </div>
          <button
            onClick={toggleSimulation}
            className={`px-4 py-2 rounded-md text-white ${isSimulating ? 'bg-red-500 hover:bg-red-600' : 'bg-blue-500 hover:bg-blue-600'}`}
          >
            {isSimulating ? 'Stop Simulation' : 'Start Simulation'}
          </button>
        </div>
      </div>
      
      {/* Market Indicators */}
      <div className="bg-gray-50 p-4 rounded-lg mb-6">
        <h3 className="text-lg font-semibold mb-3 text-gray-800">Market Indicators</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <div className="mb-4">
              <div className="flex justify-between mb-1">
                <span className="text-sm font-medium">Market Volatility</span>
                <span className="text-sm font-medium">{marketIndicators.volatility}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className={`h-2.5 rounded-full ${marketIndicators.volatility > 70 ? 'bg-red-500' : marketIndicators.volatility > 40 ? 'bg-yellow-400' : 'bg-green-500'}`} 
                  style={{ width: `${marketIndicators.volatility}%` }}
                ></div>
              </div>
            </div>
            
            <div className="mb-4">
              <div className="flex justify-between mb-1">
                <span className="text-sm font-medium">Yield Opportunity</span>
                <span className="text-sm font-medium">{marketIndicators.opportunity}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className="bg-blue-500 h-2.5 rounded-full" 
                  style={{ width: `${marketIndicators.opportunity}%` }}
                ></div>
              </div>
            </div>
          </div>
          
          <div>
            <div className="mb-4">
              <div className="flex justify-between mb-1">
                <span className="text-sm font-medium">Market Liquidity</span>
                <span className="text-sm font-medium">{marketIndicators.liquidity}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className="bg-purple-500 h-2.5 rounded-full" 
                  style={{ width: `${marketIndicators.liquidity}%` }}
                ></div>
              </div>
            </div>
            
            <div className="flex justify-between items-center mb-1">
              <span className="text-sm font-medium">Market Sentiment</span>
              {renderSentimentIndicator(marketIndicators.sentiment)}
            </div>
          </div>
        </div>
      </div>
      
      {/* Current Decision */}
      <div className="bg-gradient-to-r from-blue-50 to-indigo-50 p-4 rounded-lg mb-6">
        <h3 className="text-lg font-semibold mb-3 text-gray-800">Current AI Decision</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <div className="bg-white p-3 rounded shadow-sm">
            <div className="text-sm text-gray-500 mb-1">Risk Assessment</div>
            <div className="text-xl font-bold">{currentDecision.riskScore}/10</div>
            <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
              <div 
                className={`h-2 rounded-full ${currentDecision.riskScore > 7 ? 'bg-red-500' : currentDecision.riskScore > 4 ? 'bg-yellow-400' : 'bg-green-500'}`} 
                style={{ width: `${currentDecision.riskScore * 10}%` }}
              ></div>
            </div>
          </div>
          
          <div className="bg-white p-3 rounded shadow-sm">
            <div className="text-sm text-gray-500 mb-1">Confidence Score</div>
            <div className="text-xl font-bold">{(currentDecision.confidenceScore * 100).toFixed(0)}%</div>
            <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
              <div 
                className="bg-blue-500 h-2 rounded-full" 
                style={{ width: `${currentDecision.confidenceScore * 100}%` }}
              ></div>
            </div>
          </div>
          
          <div className="bg-white p-3 rounded shadow-sm">
            <div className="text-sm text-gray-500 mb-1">Market Sentiment</div>
            <div className="text-xl font-bold">{renderSentimentIndicator(currentDecision.marketSentiment)}</div>
            <div className="text-xs text-gray-500 mt-2">
              Updated {new Date(currentDecision.timestamp).toLocaleTimeString()}
            </div>
          </div>
        </div>
        
        <div className="bg-white p-4 rounded shadow-sm mb-4">
          <div className="text-sm text-gray-500 mb-2">AI Reasoning</div>
          <p className="text-gray-700">{currentDecision.reasoning}</p>
        </div>
        
        <div className="bg-white p-4 rounded shadow-sm">
          <div className="text-sm text-gray-500 mb-2">Recommended Strategy Allocation</div>
          <div className="space-y-3">
            {strategies.map(strategy => (
              <div key={strategy.id}>
                <div className="flex justify-between mb-1">
                  <span className="font-medium">{strategy.name}</span>
                  <span className={`text-sm ${currentDecision.recommendedStrategies.includes(strategy.id) ? 'text-green-600 font-medium' : 'text-gray-500'}`}>
                    {strategy.allocation}%
                    {currentDecision.recommendedStrategies.includes(strategy.id) && ' (Recommended)'}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className={`h-2 rounded-full ${currentDecision.recommendedStrategies.includes(strategy.id) ? 'bg-green-500' : 'bg-gray-400'}`} 
                    style={{ width: `${strategy.allocation}%` }}
                  ></div>
                </div>
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>APY: {strategy.apy}%</span>
                  <span>Risk: {strategy.risk}/10</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
      
      {/* Market Data */}
      <div className="bg-white border border-gray-200 rounded-lg overflow-hidden">
        <h3 className="text-lg font-semibold p-4 border-b text-gray-800">Market Data</h3>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Asset</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">24h Change</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Volatility</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Volume</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Yield</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {marketData.map((asset) => (
                <tr key={asset.assetName}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-800">{asset.assetName}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">${asset.price.toFixed(2)}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm">
                    <span className={asset.change24h >= 0 ? 'text-green-600' : 'text-red-600'}>
                      {asset.change24h >= 0 ? '+' : ''}{asset.change24h.toFixed(2)}%
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{(asset.volatility * 100).toFixed(1)}%</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{formatNumber(asset.volume)}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{asset.yield.toFixed(1)}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AIDecisionSimulation;
