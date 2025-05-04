import React from 'react';
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
  BarElement,
  ArcElement,
} from 'chart.js';
import { Line, Doughnut } from 'react-chartjs-2';

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

// Mock data for portfolio performance
const generatePerformanceData = () => {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const currentMonth = new Date().getMonth();
  
  // Get the last 6 months
  const labels = Array(6).fill(0).map((_, i) => {
    const monthIndex = (currentMonth - 5 + i + 12) % 12;
    return months[monthIndex];
  });
  
  // Generate cumulative portfolio value with some randomness but overall upward trend
  const baseValue = 10000;
  const values = labels.map((_, i) => {
    // Start with base value and add cumulative growth with some randomness
    return Math.round(baseValue * (1 + 0.02 * i + Math.random() * 0.02));
  });
  
  return { labels, values };
};

// Mock data for asset allocation
const generateAllocationData = () => {
  return {
    labels: ['High-Yield Strategy (8%)', 'Balanced Strategy (5%)', 'Stable-Yield Strategy (3%)'],
    values: [30, 45, 25], // Percentages allocated to each strategy
    colors: ['rgba(255, 99, 132, 0.8)', 'rgba(54, 162, 235, 0.8)', 'rgba(75, 192, 192, 0.8)'],
    hoverColors: ['rgba(255, 99, 132, 1)', 'rgba(54, 162, 235, 1)', 'rgba(75, 192, 192, 1)'],
  };
};

const PortfolioPerformance: React.FC = () => {
  const performanceData = generatePerformanceData();
  const allocationData = generateAllocationData();
  
  // Line chart data for portfolio performance
  const lineChartData = {
    labels: performanceData.labels,
    datasets: [
      {
        label: 'Portfolio Value ($)',
        data: performanceData.values,
        borderColor: 'rgba(75, 192, 192, 1)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        fill: true,
        tension: 0.4,
      },
    ],
  };
  
  // Line chart options
  const lineChartOptions = {
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
        text: 'Portfolio Performance (Last 6 Months)',
        color: 'rgba(229, 231, 235, 1)', // text-gray-200
      },
      tooltip: {
        mode: 'index' as const,
        intersect: false,
      },
    },
    scales: {
      y: {
        beginAtZero: false,
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
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
        },
      },
    },
  };
  
  // Doughnut chart data for asset allocation
  const doughnutChartData = {
    labels: allocationData.labels,
    datasets: [
      {
        data: allocationData.values,
        backgroundColor: allocationData.colors,
        hoverBackgroundColor: allocationData.hoverColors,
        borderWidth: 2,
        borderColor: '#1f2937', // bg-gray-800
      },
    ],
  };
  
  // Doughnut chart options
  const doughnutChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'right' as const,
        labels: {
          color: 'rgba(229, 231, 235, 1)', // text-gray-200
          padding: 20,
          font: {
            size: 12,
          },
        },
      },
      title: {
        display: true,
        text: 'Current Asset Allocation',
        color: 'rgba(229, 231, 235, 1)', // text-gray-200
      },
    },
    cutout: '70%',
  };
  
  // Calculate total portfolio value
  const totalValue = performanceData.values[performanceData.values.length - 1];
  
  // Calculate portfolio growth
  const startValue = performanceData.values[0];
  const growthAmount = totalValue - startValue;
  const growthPercentage = ((growthAmount / startValue) * 100).toFixed(2);
  const isPositiveGrowth = growthAmount >= 0;
  
  return (
    <div className="bg-gray-800 rounded-xl shadow-lg border border-gray-700 overflow-hidden">
      <div className="p-5">
        <h2 className="text-xl font-bold text-white mb-4">Portfolio Dashboard</h2>
        
        {/* Portfolio summary */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">Total Value</p>
            <p className="text-2xl font-bold text-white">${totalValue.toLocaleString()}</p>
          </div>
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">Growth (6 Months)</p>
            <p className={`text-2xl font-bold ${isPositiveGrowth ? 'text-green-400' : 'text-red-400'}`}>
              {isPositiveGrowth ? '+' : ''}{growthPercentage}%
            </p>
          </div>
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">AI Optimization Status</p>
            <p className="text-lg font-semibold text-blue-400">Optimized</p>
            <p className="text-xs text-gray-400">Last rebalanced: 2 days ago</p>
          </div>
        </div>
        
        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Line chart for portfolio performance */}
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <div style={{ height: '300px' }}>
              <Line data={lineChartData} options={lineChartOptions} />
            </div>
          </div>
          
          {/* Doughnut chart for asset allocation */}
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700">
            <div style={{ height: '300px' }}>
              <Doughnut data={doughnutChartData} options={doughnutChartOptions} />
            </div>
          </div>
        </div>
        
        {/* Strategy performance comparison */}
        <div className="mt-6">
          <h3 className="text-lg font-semibold text-white mb-3">Strategy Performance</h3>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-700">
              <thead>
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Strategy
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Allocation
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Current APY
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Value
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    30-Day Return
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-700">
                <tr>
                  <td className="px-4 py-3 text-sm text-gray-200">High-Yield Strategy</td>
                  <td className="px-4 py-3 text-sm text-gray-200">30%</td>
                  <td className="px-4 py-3 text-sm text-green-400">8.0%</td>
                  <td className="px-4 py-3 text-sm text-gray-200">${Math.round(totalValue * 0.3).toLocaleString()}</td>
                  <td className="px-4 py-3 text-sm text-green-400">+2.1%</td>
                </tr>
                <tr>
                  <td className="px-4 py-3 text-sm text-gray-200">Balanced Strategy</td>
                  <td className="px-4 py-3 text-sm text-gray-200">45%</td>
                  <td className="px-4 py-3 text-sm text-green-400">5.0%</td>
                  <td className="px-4 py-3 text-sm text-gray-200">${Math.round(totalValue * 0.45).toLocaleString()}</td>
                  <td className="px-4 py-3 text-sm text-green-400">+1.3%</td>
                </tr>
                <tr>
                  <td className="px-4 py-3 text-sm text-gray-200">Stable-Yield Strategy</td>
                  <td className="px-4 py-3 text-sm text-gray-200">25%</td>
                  <td className="px-4 py-3 text-sm text-green-400">3.0%</td>
                  <td className="px-4 py-3 text-sm text-gray-200">${Math.round(totalValue * 0.25).toLocaleString()}</td>
                  <td className="px-4 py-3 text-sm text-green-400">+0.7%</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        
        {/* AI Insights */}
        <div className="mt-6 bg-blue-900/30 border border-blue-800 rounded-lg p-4">
          <h3 className="text-lg font-semibold text-blue-300 mb-2">AI Insights</h3>
          <p className="text-gray-300 text-sm mb-3">
            Based on current market conditions and your risk profile, NapFi AI recommends the following:
          </p>
          <ul className="list-disc list-inside text-gray-300 text-sm space-y-1">
            <li>Maintain current allocation to capture optimal risk-adjusted returns</li>
            <li>Market volatility is decreasing, consider increasing allocation to High-Yield Strategy next month</li>
            <li>Current portfolio efficiency score: <span className="text-green-400 font-semibold">92/100</span></li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default PortfolioPerformance;
