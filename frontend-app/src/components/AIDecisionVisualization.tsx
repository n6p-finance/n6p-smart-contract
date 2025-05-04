import React, { useState } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler,
  ArcElement,
} from 'chart.js';
import { Bar, Line } from 'react-chartjs-2';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

const AIDecisionVisualization: React.FC = () => {
  // State for time period selection
  const [timePeriod, setTimePeriod] = useState<'1m' | '3m' | '6m' | '1y'>('3m');
  
  // Mock data for AI allocation decisions over time
  const generateAllocationHistory = (period: '1m' | '3m' | '6m' | '1y') => {
    // Number of data points based on period
    const dataPoints = period === '1m' ? 4 : period === '3m' ? 12 : period === '6m' ? 24 : 52;
    
    // Generate dates for x-axis
    const dates = Array(dataPoints).fill(0).map((_, i) => {
      const date = new Date();
      date.setDate(date.getDate() - (dataPoints - i - 1) * (period === '1m' ? 7 : period === '3m' ? 7 : period === '6m' ? 7 : 7));
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });
    
    // Generate allocation percentages for each strategy
    // Simulate AI adjusting allocations based on market conditions
    const highYieldAllocation = dates.map((_, i) => {
      const base = 30;
      const trend = Math.sin(i / (dataPoints / 4)) * 10; // Cyclical trend
      const random = Math.random() * 5 - 2.5; // Random noise
      return Math.max(15, Math.min(45, Math.round(base + trend + random)));
    });
    
    const balancedAllocation = dates.map((_, i) => {
      const base = 45;
      const trend = -Math.sin(i / (dataPoints / 4)) * 5; // Inverse cyclical trend
      const random = Math.random() * 5 - 2.5; // Random noise
      return Math.max(30, Math.min(55, Math.round(base + trend + random)));
    });
    
    // Stable yield is whatever remains to make 100%
    const stableYieldAllocation = dates.map((_, i) => {
      return 100 - highYieldAllocation[i] - balancedAllocation[i];
    });
    
    return {
      dates,
      highYieldAllocation,
      balancedAllocation,
      stableYieldAllocation
    };
  };
  
  // Generate performance comparison data
  const generatePerformanceComparison = (period: '1m' | '3m' | '6m' | '1y') => {
    // Number of data points based on period
    const dataPoints = period === '1m' ? 30 : period === '3m' ? 90 : period === '6m' ? 180 : 365;
    const step = Math.max(1, Math.floor(dataPoints / 30)); // Show at most 30 points on chart
    
    // Generate dates for x-axis
    const dates = [];
    for (let i = 0; i < dataPoints; i += step) {
      const date = new Date();
      date.setDate(date.getDate() - (dataPoints - i - 1));
      dates.push(date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
    }
    
    // Base value and growth rates
    const baseValue = 10000;
    const aiAnnualGrowthRate = 0.12; // 12% annual growth
    const traditionalAnnualGrowthRate = 0.08; // 8% annual growth
    const fixedIncomeAnnualGrowthRate = 0.04; // 4% annual growth
    
    // Calculate daily growth rates
    const aiDailyGrowthRate = Math.pow(1 + aiAnnualGrowthRate, 1/365) - 1;
    const traditionalDailyGrowthRate = Math.pow(1 + traditionalAnnualGrowthRate, 1/365) - 1;
    const fixedIncomeDailyGrowthRate = Math.pow(1 + fixedIncomeAnnualGrowthRate, 1/365) - 1;
    
    // Generate performance values with some randomness
    let aiValue = baseValue;
    let traditionalValue = baseValue;
    let fixedIncomeValue = baseValue;
    
    const aiPerformance = [];
    const traditionalPerformance = [];
    const fixedIncomePerformance = [];
    
    for (let i = 0; i < dataPoints; i++) {
      // Add some randomness to daily returns
      const aiRandom = (Math.random() * 0.01) - 0.005; // -0.5% to +0.5%
      const traditionalRandom = (Math.random() * 0.008) - 0.004; // -0.4% to +0.4%
      const fixedIncomeRandom = (Math.random() * 0.002) - 0.001; // -0.1% to +0.1%
      
      aiValue *= (1 + aiDailyGrowthRate + aiRandom);
      traditionalValue *= (1 + traditionalDailyGrowthRate + traditionalRandom);
      fixedIncomeValue *= (1 + fixedIncomeDailyGrowthRate + fixedIncomeRandom);
      
      if (i % step === 0) {
        aiPerformance.push(Math.round(aiValue));
        traditionalPerformance.push(Math.round(traditionalValue));
        fixedIncomePerformance.push(Math.round(fixedIncomeValue));
      }
    }
    
    return {
      dates,
      aiPerformance,
      traditionalPerformance,
      fixedIncomePerformance
    };
  };
  
  // Get allocation data based on selected time period
  const allocationData = generateAllocationHistory(timePeriod);
  const performanceData = generatePerformanceComparison(timePeriod);
  
  // Allocation history chart data
  const allocationChartData = {
    labels: allocationData.dates,
    datasets: [
      {
        label: 'High-Yield Strategy (8% APY)',
        data: allocationData.highYieldAllocation,
        backgroundColor: 'rgba(255, 99, 132, 0.8)',
        borderColor: 'rgba(255, 99, 132, 1)',
        borderWidth: 1,
        stack: 'Stack 0',
      },
      {
        label: 'Balanced Strategy (5% APY)',
        data: allocationData.balancedAllocation,
        backgroundColor: 'rgba(54, 162, 235, 0.8)',
        borderColor: 'rgba(54, 162, 235, 1)',
        borderWidth: 1,
        stack: 'Stack 0',
      },
      {
        label: 'Stable-Yield Strategy (3% APY)',
        data: allocationData.stableYieldAllocation,
        backgroundColor: 'rgba(75, 192, 192, 0.8)',
        borderColor: 'rgba(75, 192, 192, 1)',
        borderWidth: 1,
        stack: 'Stack 0',
      },
    ],
  };
  
  // Allocation chart options
  const allocationChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top' as const,
        labels: {
          color: 'rgba(229, 231, 235, 1)', // text-gray-200
        },
      },
      title: {
        display: true,
        text: 'AI Allocation Decisions Over Time',
        color: 'rgba(229, 231, 235, 1)', // text-gray-200
      },
      tooltip: {
        mode: 'index' as const,
        intersect: false,
        callbacks: {
          label: function(context: any) {
            return `${context.dataset.label}: ${context.raw}%`;
          }
        }
      },
    },
    scales: {
      y: {
        stacked: true,
        min: 0,
        max: 100,
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
          callback: function(this: any, value: any) {
            return `${value}%`;
          },
        },
      },
      x: {
        stacked: true,
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
  
  // Performance comparison chart data
  const performanceChartData = {
    labels: performanceData.dates,
    datasets: [
      {
        label: 'NapFi AI Optimized',
        data: performanceData.aiPerformance,
        borderColor: 'rgba(75, 192, 192, 1)',
        backgroundColor: 'rgba(75, 192, 192, 0.1)',
        borderWidth: 2,
        fill: false,
        tension: 0.4,
      },
      {
        label: 'Traditional 60/40 Portfolio',
        data: performanceData.traditionalPerformance,
        borderColor: 'rgba(54, 162, 235, 1)',
        backgroundColor: 'rgba(54, 162, 235, 0.1)',
        borderWidth: 2,
        fill: false,
        tension: 0.4,
      },
      {
        label: 'Fixed Income Only',
        data: performanceData.fixedIncomePerformance,
        borderColor: 'rgba(255, 159, 64, 1)',
        backgroundColor: 'rgba(255, 159, 64, 0.1)',
        borderWidth: 2,
        fill: false,
        tension: 0.4,
      },
    ],
  };
  
  // Performance chart options
  const performanceChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top' as const,
        labels: {
          color: 'rgba(229, 231, 235, 1)', // text-gray-200
        },
      },
      title: {
        display: true,
        text: 'Performance Comparison',
        color: 'rgba(229, 231, 235, 1)', // text-gray-200
      },
      tooltip: {
        mode: 'index' as const,
        intersect: false,
        callbacks: {
          label: function(context: any) {
            return `${context.dataset.label}: $${context.raw.toLocaleString()}`;
          }
        }
      },
    },
    scales: {
      y: {
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
          callback: function(this: any, value: any) {
            return `$${Number(value).toLocaleString()}`;
          },
        },
      },
      x: {
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
          display: false,
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
          maxRotation: 45,
          minRotation: 45,
          maxTicksLimit: 10,
        },
      },
    },
  };
  
  // Calculate performance metrics
  const calculatePerformanceMetrics = () => {
    const aiStart = performanceData.aiPerformance[0];
    const aiEnd = performanceData.aiPerformance[performanceData.aiPerformance.length - 1];
    const aiReturn = ((aiEnd - aiStart) / aiStart) * 100;
    
    const traditionalStart = performanceData.traditionalPerformance[0];
    const traditionalEnd = performanceData.traditionalPerformance[performanceData.traditionalPerformance.length - 1];
    const traditionalReturn = ((traditionalEnd - traditionalStart) / traditionalStart) * 100;
    
    const fixedIncomeStart = performanceData.fixedIncomePerformance[0];
    const fixedIncomeEnd = performanceData.fixedIncomePerformance[performanceData.fixedIncomePerformance.length - 1];
    const fixedIncomeReturn = ((fixedIncomeEnd - fixedIncomeStart) / fixedIncomeStart) * 100;
    
    const aiOutperformance = aiReturn - traditionalReturn;
    
    return {
      aiReturn: aiReturn.toFixed(2),
      traditionalReturn: traditionalReturn.toFixed(2),
      fixedIncomeReturn: fixedIncomeReturn.toFixed(2),
      aiOutperformance: aiOutperformance.toFixed(2),
    };
  };
  
  const metrics = calculatePerformanceMetrics();
  
  // AI decision factors - simulating the AI's reasoning
  const aiDecisionFactors = [
    {
      factor: "Market Volatility",
      impact: "Medium",
      description: "Recent market volatility has decreased, allowing for slightly higher risk exposure.",
      action: "Increased allocation to High-Yield Strategy by 3%"
    },
    {
      factor: "Interest Rate Trends",
      impact: "High",
      description: "Central bank signaling potential rate cuts in the next quarter.",
      action: "Maintained significant allocation to Balanced Strategy"
    },
    {
      factor: "Economic Indicators",
      impact: "Medium",
      description: "Leading economic indicators show moderate growth with low inflation.",
      action: "Reduced allocation to Stable-Yield Strategy by 2%"
    },
    {
      factor: "Risk Tolerance Profile",
      impact: "High",
      description: "User's risk profile indicates moderate risk tolerance.",
      action: "Maintained balanced approach across all strategies"
    }
  ];
  
  return (
    <div className="bg-gray-800 rounded-xl shadow-lg border border-gray-700 overflow-hidden">
      <div className="p-5">
        <h2 className="text-xl font-bold text-white mb-4">AI Decision Analysis</h2>
        
        {/* Time period selector */}
        <div className="flex space-x-2 mb-6">
          <button 
            onClick={() => setTimePeriod('1m')}
            className={`px-3 py-1 rounded-md text-sm font-medium ${
              timePeriod === '1m' 
                ? 'bg-blue-600 text-white' 
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
          >
            1 Month
          </button>
          <button 
            onClick={() => setTimePeriod('3m')}
            className={`px-3 py-1 rounded-md text-sm font-medium ${
              timePeriod === '3m' 
                ? 'bg-blue-600 text-white' 
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
          >
            3 Months
          </button>
          <button 
            onClick={() => setTimePeriod('6m')}
            className={`px-3 py-1 rounded-md text-sm font-medium ${
              timePeriod === '6m' 
                ? 'bg-blue-600 text-white' 
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
          >
            6 Months
          </button>
          <button 
            onClick={() => setTimePeriod('1y')}
            className={`px-3 py-1 rounded-md text-sm font-medium ${
              timePeriod === '1y' 
                ? 'bg-blue-600 text-white' 
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
          >
            1 Year
          </button>
        </div>
        
        {/* Performance metrics */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">NapFi AI Return</p>
            <p className="text-2xl font-bold text-green-400">+{metrics.aiReturn}%</p>
          </div>
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">Traditional Portfolio</p>
            <p className="text-2xl font-bold text-blue-400">+{metrics.traditionalReturn}%</p>
          </div>
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">Fixed Income Only</p>
            <p className="text-2xl font-bold text-yellow-400">+{metrics.fixedIncomeReturn}%</p>
          </div>
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">AI Outperformance</p>
            <p className="text-2xl font-bold text-indigo-400">+{metrics.aiOutperformance}%</p>
          </div>
        </div>
        
        {/* Charts */}
        <div className="grid grid-cols-1 gap-6 mb-6">
          {/* Performance comparison chart */}
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <div style={{ height: '300px' }}>
              <Line data={performanceChartData} options={performanceChartOptions} />
            </div>
          </div>
          
          {/* AI allocation decisions chart */}
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <div style={{ height: '300px' }}>
              <Bar data={allocationChartData} options={allocationChartOptions} />
            </div>
          </div>
        </div>
        
        {/* AI Decision Factors */}
        <div className="mb-6">
          <h3 className="text-lg font-semibold text-white mb-3">AI Decision Factors</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {aiDecisionFactors.map((factor, index) => (
              <div key={index} className="bg-gray-900 rounded-lg p-4 border border-gray-700">
                <div className="flex justify-between items-center mb-2">
                  <h4 className="font-semibold text-white">{factor.factor}</h4>
                  <span className={`px-2 py-1 text-xs rounded ${
                    factor.impact === 'High' ? 'bg-red-900/50 text-red-400' : 
                    factor.impact === 'Medium' ? 'bg-yellow-900/50 text-yellow-400' : 
                    'bg-green-900/50 text-green-400'
                  }`}>
                    {factor.impact} Impact
                  </span>
                </div>
                <p className="text-gray-300 text-sm mb-2">{factor.description}</p>
                <p className="text-blue-400 text-sm font-medium">{factor.action}</p>
              </div>
            ))}
          </div>
        </div>
        
        {/* AI Reasoning Summary */}
        <div className="bg-blue-900/30 border border-blue-800 rounded-lg p-4">
          <h3 className="text-lg font-semibold text-blue-300 mb-2">AI Reasoning Summary</h3>
          <p className="text-gray-300 text-sm mb-3">
            NapFi AI continuously analyzes market conditions and adjusts allocations to optimize returns while managing risk:
          </p>
          <ul className="list-disc list-inside text-gray-300 text-sm space-y-2">
            <li>
              <span className="font-medium text-white">Dynamic Rebalancing:</span> The AI has adjusted allocations 8 times in the past {timePeriod === '1m' ? 'month' : timePeriod === '3m' ? '3 months' : timePeriod === '6m' ? '6 months' : 'year'}, compared to quarterly rebalancing in traditional portfolios.
            </li>
            <li>
              <span className="font-medium text-white">Risk-Adjusted Returns:</span> The AI has achieved {metrics.aiOutperformance}% higher returns than a traditional portfolio with similar risk levels.
            </li>
            <li>
              <span className="font-medium text-white">Market Timing:</span> The AI increased high-yield exposure during market uptrends and shifted to stable strategies during volatility.
            </li>
            <li>
              <span className="font-medium text-white">Personalization:</span> Allocations are tailored to your specific risk tolerance and investment goals.
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default AIDecisionVisualization;
