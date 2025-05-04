import React, { useState, useEffect } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js';
import { Line } from 'react-chartjs-2';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

// Market condition types
type MarketCondition = 'bullish' | 'bearish' | 'neutral' | 'volatile';

// Market indicator type
interface MarketIndicator {
  name: string;
  value: number;
  change: number;
  trend: 'up' | 'down' | 'neutral';
}

// AI reaction type
interface AIReaction {
  action: string;
  reasoning: string;
  allocation: {
    highYield: number;
    balanced: number;
    stableYield: number;
  };
}

const MarketConditions: React.FC = () => {
  // State for market condition
  const [marketCondition, setMarketCondition] = useState<MarketCondition>('neutral');
  
  // State for market indicators
  const [marketIndicators, setMarketIndicators] = useState<MarketIndicator[]>([
    { name: 'S&P 500', value: 5284.32, change: 0.2, trend: 'up' },
    { name: 'NASDAQ', value: 16542.78, change: 0.35, trend: 'up' },
    { name: 'US 10Y Treasury', value: 4.12, change: -0.03, trend: 'down' },
    { name: 'VIX Volatility', value: 18.45, change: -0.8, trend: 'down' },
    { name: 'DXY Dollar Index', value: 102.35, change: -0.15, trend: 'down' },
  ]);
  
  // State for historical market data (last 30 data points)
  const [historicalData, setHistoricalData] = useState<{
    labels: string[];
    sp500: number[];
    nasdaq: number[];
    treasury: number[];
    vix: number[];
  }>({
    labels: Array(30).fill('').map((_, i) => {
      const date = new Date();
      date.setMinutes(date.getMinutes() - (30 - i) * 15);
      return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    }),
    sp500: Array(30).fill(0).map((_, i) => 5250 + Math.random() * 50),
    nasdaq: Array(30).fill(0).map((_, i) => 16400 + Math.random() * 200),
    treasury: Array(30).fill(0).map((_, i) => 4.1 + (Math.random() - 0.5) * 0.1),
    vix: Array(30).fill(0).map((_, i) => 18 + (Math.random() - 0.5) * 3),
  });
  
  // State for AI reaction
  const [aiReaction, setAIReaction] = useState<AIReaction>({
    action: 'Maintaining current allocation',
    reasoning: 'Market conditions are stable with moderate growth indicators.',
    allocation: {
      highYield: 30,
      balanced: 45,
      stableYield: 25,
    },
  });
  
  // Function to update market data
  const updateMarketData = () => {
    // Generate random market movements
    const randomFactor = Math.random();
    let newCondition: MarketCondition = marketCondition;
    
    // Randomly change market condition (with some persistence)
    if (Math.random() < 0.15) {
      const conditions: MarketCondition[] = ['bullish', 'bearish', 'neutral', 'volatile'];
      newCondition = conditions[Math.floor(Math.random() * conditions.length)];
      setMarketCondition(newCondition);
    }
    
    // Update market indicators based on condition
    const newIndicators = marketIndicators.map(indicator => {
      let changeMultiplier = 1;
      
      // Adjust change based on market condition
      if (newCondition === 'bullish') {
        changeMultiplier = indicator.name.includes('VIX') ? -1.5 : 2;
      } else if (newCondition === 'bearish') {
        changeMultiplier = indicator.name.includes('VIX') ? 2 : -1.5;
      } else if (newCondition === 'volatile') {
        changeMultiplier = 3 * (Math.random() > 0.5 ? 1 : -1);
      }
      
      // Calculate new change
      const newChange = (Math.random() - 0.45) * changeMultiplier;
      
      // Calculate new value
      const newValue = indicator.value * (1 + newChange / 100);
      
      // Determine trend
      const newTrend: 'up' | 'down' | 'neutral' = newChange > 0.05 ? 'up' : newChange < -0.05 ? 'down' : 'neutral';
      
      return {
        ...indicator,
        value: Number(newValue.toFixed(indicator.name.includes('Treasury') || indicator.name.includes('VIX') ? 2 : 2)),
        change: Number(newChange.toFixed(2)),
        trend: newTrend,
      };
    });
    
    setMarketIndicators(newIndicators);
    
    // Update historical data
    const newLabels = [...historicalData.labels.slice(1)];
    const now = new Date();
    newLabels.push(now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }));
    
    const sp500Value = newIndicators[0].value;
    const nasdaqValue = newIndicators[1].value;
    const treasuryValue = newIndicators[2].value;
    const vixValue = newIndicators[3].value;
    
    setHistoricalData({
      labels: newLabels,
      sp500: [...historicalData.sp500.slice(1), sp500Value],
      nasdaq: [...historicalData.nasdaq.slice(1), nasdaqValue],
      treasury: [...historicalData.treasury.slice(1), treasuryValue],
      vix: [...historicalData.vix.slice(1), vixValue],
    });
    
    // Update AI reaction based on market condition
    let newAllocation = { ...aiReaction.allocation };
    let action = '';
    let reasoning = '';
    
    switch (newCondition) {
      case 'bullish':
        // In bullish markets, increase high-yield allocation
        newAllocation = {
          highYield: Math.min(50, aiReaction.allocation.highYield + Math.floor(Math.random() * 3)),
          balanced: Math.max(30, aiReaction.allocation.balanced - Math.floor(Math.random() * 2)),
          stableYield: Math.max(15, 100 - (newAllocation.highYield + newAllocation.balanced)),
        };
        action = 'Increasing high-yield allocation';
        reasoning = 'Strong market performance indicates growth opportunities. Reducing stable-yield exposure to capitalize on bullish trend.';
        break;
        
      case 'bearish':
        // In bearish markets, increase stable-yield allocation
        newAllocation = {
          highYield: Math.max(15, aiReaction.allocation.highYield - Math.floor(Math.random() * 3)),
          balanced: Math.max(35, aiReaction.allocation.balanced - Math.floor(Math.random() * 2)),
          stableYield: Math.min(50, 100 - (newAllocation.highYield + newAllocation.balanced)),
        };
        action = 'Increasing stable-yield allocation';
        reasoning = 'Market downturn detected. Reducing high-yield exposure to protect capital and increase stable-yield allocation for safety.';
        break;
        
      case 'volatile':
        // In volatile markets, increase balanced allocation
        newAllocation = {
          highYield: Math.max(20, aiReaction.allocation.highYield - Math.floor(Math.random() * 2)),
          balanced: Math.min(55, aiReaction.allocation.balanced + Math.floor(Math.random() * 3)),
          stableYield: Math.max(15, 100 - (newAllocation.highYield + newAllocation.balanced)),
        };
        action = 'Rebalancing for volatility';
        reasoning = 'Increased market volatility detected. Adjusting to more balanced approach to mitigate risk while maintaining growth potential.';
        break;
        
      case 'neutral':
        // In neutral markets, maintain balanced allocation
        newAllocation = {
          highYield: Math.min(35, Math.max(25, aiReaction.allocation.highYield + (Math.random() > 0.5 ? 1 : -1))),
          balanced: Math.min(50, Math.max(40, aiReaction.allocation.balanced + (Math.random() > 0.5 ? 1 : -1))),
          stableYield: Math.max(15, 100 - (newAllocation.highYield + newAllocation.balanced)),
        };
        action = 'Fine-tuning allocation';
        reasoning = 'Market conditions are stable. Maintaining diversified allocation with slight adjustments based on sector performance.';
        break;
    }
    
    // Ensure allocations sum to 100%
    const total = newAllocation.highYield + newAllocation.balanced + newAllocation.stableYield;
    if (total !== 100) {
      newAllocation.balanced += (100 - total);
    }
    
    setAIReaction({
      action,
      reasoning,
      allocation: newAllocation,
    });
  };
  
  // Update market data every 5 seconds
  useEffect(() => {
    const interval = setInterval(updateMarketData, 5000);
    return () => clearInterval(interval);
  }, [marketCondition, marketIndicators, aiReaction]);
  
  // Chart data for market indices
  const marketIndexChartData = {
    labels: historicalData.labels,
    datasets: [
      {
        label: 'S&P 500',
        data: historicalData.sp500,
        borderColor: 'rgba(75, 192, 192, 1)',
        backgroundColor: 'rgba(75, 192, 192, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        yAxisID: 'y',
      },
      {
        label: 'NASDAQ',
        data: historicalData.nasdaq,
        borderColor: 'rgba(54, 162, 235, 1)',
        backgroundColor: 'rgba(54, 162, 235, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        yAxisID: 'y1',
        hidden: true, // Hidden by default
      },
    ],
  };
  
  // Chart options for market indices
  const marketIndexChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
      mode: 'index' as const,
      intersect: false,
    },
    plugins: {
      legend: {
        position: 'top' as const,
        labels: {
          color: 'rgba(229, 231, 235, 1)', // text-gray-200
        },
      },
      title: {
        display: true,
        text: 'Market Indices (Live)',
        color: 'rgba(229, 231, 235, 1)', // text-gray-200
      },
    },
    scales: {
      y: {
        type: 'linear' as const,
        display: true,
        position: 'left' as const,
        title: {
          display: true,
          text: 'S&P 500',
          color: 'rgba(75, 192, 192, 1)',
        },
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
        },
      },
      y1: {
        type: 'linear' as const,
        display: true,
        position: 'right' as const,
        title: {
          display: true,
          text: 'NASDAQ',
          color: 'rgba(54, 162, 235, 1)',
        },
        grid: {
          drawOnChartArea: false,
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
        },
      },
      x: {
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
          maxRotation: 45,
          minRotation: 45,
        },
      },
    },
  };
  
  // Chart data for market indicators
  const marketIndicatorChartData = {
    labels: historicalData.labels,
    datasets: [
      {
        label: '10Y Treasury',
        data: historicalData.treasury,
        borderColor: 'rgba(255, 206, 86, 1)',
        backgroundColor: 'rgba(255, 206, 86, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        yAxisID: 'y',
      },
      {
        label: 'VIX Volatility',
        data: historicalData.vix,
        borderColor: 'rgba(255, 99, 132, 1)',
        backgroundColor: 'rgba(255, 99, 132, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        yAxisID: 'y1',
      },
    ],
  };
  
  // Chart options for market indicators
  const marketIndicatorChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
      mode: 'index' as const,
      intersect: false,
    },
    plugins: {
      legend: {
        position: 'top' as const,
        labels: {
          color: 'rgba(229, 231, 235, 1)', // text-gray-200
        },
      },
      title: {
        display: true,
        text: 'Market Indicators (Live)',
        color: 'rgba(229, 231, 235, 1)', // text-gray-200
      },
    },
    scales: {
      y: {
        type: 'linear' as const,
        display: true,
        position: 'left' as const,
        title: {
          display: true,
          text: '10Y Treasury Yield (%)',
          color: 'rgba(255, 206, 86, 1)',
        },
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
        },
      },
      y1: {
        type: 'linear' as const,
        display: true,
        position: 'right' as const,
        title: {
          display: true,
          text: 'VIX Volatility Index',
          color: 'rgba(255, 99, 132, 1)',
        },
        grid: {
          drawOnChartArea: false,
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
        },
      },
      x: {
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
          maxRotation: 45,
          minRotation: 45,
        },
      },
    },
  };
  
  // Get color based on trend
  const getTrendColor = (trend: 'up' | 'down' | 'neutral') => {
    switch (trend) {
      case 'up':
        return 'text-green-400';
      case 'down':
        return 'text-red-400';
      default:
        return 'text-gray-400';
    }
  };
  
  // Get market condition style
  const getMarketConditionStyle = (condition: MarketCondition) => {
    switch (condition) {
      case 'bullish':
        return 'bg-green-900/50 text-green-400 border-green-800';
      case 'bearish':
        return 'bg-red-900/50 text-red-400 border-red-800';
      case 'volatile':
        return 'bg-yellow-900/50 text-yellow-400 border-yellow-800';
      case 'neutral':
        return 'bg-blue-900/50 text-blue-400 border-blue-800';
    }
  };
  
  // Get market condition description
  const getMarketConditionDescription = (condition: MarketCondition) => {
    switch (condition) {
      case 'bullish':
        return 'Markets are showing strong upward momentum with positive sentiment.';
      case 'bearish':
        return 'Markets are trending downward with negative sentiment.';
      case 'volatile':
        return 'Markets are experiencing significant price swings and uncertainty.';
      case 'neutral':
        return 'Markets are stable with balanced buying and selling pressure.';
    }
  };
  
  return (
    <div className="bg-gray-800 rounded-xl shadow-lg border border-gray-700 overflow-hidden">
      <div className="p-5">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold text-white">Live Market Conditions</h2>
          <div className={`px-3 py-1 rounded-full border ${getMarketConditionStyle(marketCondition)}`}>
            <span className="font-medium capitalize">{marketCondition} Market</span>
          </div>
        </div>
        
        <p className="text-gray-300 text-sm mb-6">
          {getMarketConditionDescription(marketCondition)}
        </p>
        
        {/* Market indicators */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
          {marketIndicators.map((indicator, index) => (
            <div key={index} className="bg-gray-900 rounded-lg p-3 border border-gray-700">
              <p className="text-gray-400 text-xs">{indicator.name}</p>
              <p className="text-lg font-bold text-white">
                {indicator.name.includes('Treasury') ? `${indicator.value}%` : indicator.value.toLocaleString()}
              </p>
              <p className={`text-sm ${getTrendColor(indicator.trend)}`}>
                {indicator.change > 0 ? '+' : ''}{indicator.change}%
              </p>
            </div>
          ))}
        </div>
        
        {/* Charts */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          {/* Market indices chart */}
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <div style={{ height: '250px' }}>
              <Line data={marketIndexChartData} options={marketIndexChartOptions} />
            </div>
          </div>
          
          {/* Market indicators chart */}
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <div style={{ height: '250px' }}>
              <Line data={marketIndicatorChartData} options={marketIndicatorChartOptions} />
            </div>
          </div>
        </div>
        
        {/* AI reaction */}
        <div className="bg-gray-900 rounded-lg p-4 border border-gray-700 mb-6">
          <h3 className="text-lg font-semibold text-white mb-3">AI Reaction to Market Conditions</h3>
          
          <div className="flex flex-col md:flex-row gap-6">
            <div className="flex-1">
              <div className="mb-4">
                <p className="text-blue-400 font-medium mb-1">Current Action</p>
                <p className="text-gray-200">{aiReaction.action}</p>
              </div>
              
              <div>
                <p className="text-blue-400 font-medium mb-1">Reasoning</p>
                <p className="text-gray-300 text-sm">{aiReaction.reasoning}</p>
              </div>
            </div>
            
            <div className="flex-1">
              <p className="text-blue-400 font-medium mb-2">Real-time Allocation</p>
              
              {/* High-yield allocation */}
              <div className="mb-3">
                <div className="flex justify-between mb-1">
                  <span className="text-sm text-gray-300">High-Yield Strategy (8% APY)</span>
                  <span className="text-sm text-gray-300">{aiReaction.allocation.highYield}%</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className="h-2 rounded-full bg-red-500"
                    style={{ width: `${aiReaction.allocation.highYield}%` }}
                  ></div>
                </div>
              </div>
              
              {/* Balanced allocation */}
              <div className="mb-3">
                <div className="flex justify-between mb-1">
                  <span className="text-sm text-gray-300">Balanced Strategy (5% APY)</span>
                  <span className="text-sm text-gray-300">{aiReaction.allocation.balanced}%</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className="h-2 rounded-full bg-blue-500"
                    style={{ width: `${aiReaction.allocation.balanced}%` }}
                  ></div>
                </div>
              </div>
              
              {/* Stable-yield allocation */}
              <div className="mb-3">
                <div className="flex justify-between mb-1">
                  <span className="text-sm text-gray-300">Stable-Yield Strategy (3% APY)</span>
                  <span className="text-sm text-gray-300">{aiReaction.allocation.stableYield}%</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className="h-2 rounded-full bg-green-500"
                    style={{ width: `${aiReaction.allocation.stableYield}%` }}
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        {/* Live data notice */}
        <div className="text-center text-gray-400 text-xs">
          <p>This is simulated market data for demonstration purposes.</p>
          <p>Data updates every 5 seconds to simulate real-time market conditions.</p>
        </div>
      </div>
    </div>
  );
};

export default MarketConditions;
