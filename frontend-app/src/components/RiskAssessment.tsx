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
import { Scatter } from 'react-chartjs-2';

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

const RiskAssessment: React.FC = () => {
  // Mock data for risk-reward scatter plot
  const scatterData = {
    datasets: [
      {
        label: 'High-Yield Strategy',
        data: [{ x: 8.0, y: 7.5 }], // APY vs Risk (1-10)
        backgroundColor: 'rgba(255, 99, 132, 0.8)',
        borderColor: 'rgba(255, 99, 132, 1)',
        borderWidth: 1,
        pointRadius: 8,
        pointHoverRadius: 10,
      },
      {
        label: 'Balanced Strategy',
        data: [{ x: 5.0, y: 4.5 }], // APY vs Risk (1-10)
        backgroundColor: 'rgba(54, 162, 235, 0.8)',
        borderColor: 'rgba(54, 162, 235, 1)',
        borderWidth: 1,
        pointRadius: 8,
        pointHoverRadius: 10,
      },
      {
        label: 'Stable-Yield Strategy',
        data: [{ x: 3.0, y: 2.0 }], // APY vs Risk (1-10)
        backgroundColor: 'rgba(75, 192, 192, 0.8)',
        borderColor: 'rgba(75, 192, 192, 1)',
        borderWidth: 1,
        pointRadius: 8,
        pointHoverRadius: 10,
      },
      {
        label: 'Current Portfolio',
        data: [{ x: 5.3, y: 4.8 }], // Weighted average APY vs Risk
        backgroundColor: 'rgba(255, 206, 86, 0.8)',
        borderColor: 'rgba(255, 206, 86, 1)',
        borderWidth: 2,
        pointRadius: 10,
        pointHoverRadius: 12,
        pointStyle: 'star',
      },
    ],
  };

  // Scatter plot options
  const scatterOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top' as const,
        labels: {
          color: 'rgba(229, 231, 235, 1)', // text-gray-200
          padding: 20,
        },
      },
      title: {
        display: true,
        text: 'Risk vs. Return Analysis',
        color: 'rgba(229, 231, 235, 1)', // text-gray-200
      },
      tooltip: {
        callbacks: {
          label: function(context: any) {
            const label = context.dataset.label || '';
            const x = context.parsed.x.toFixed(1);
            const y = context.parsed.y.toFixed(1);
            return `${label}: ${x}% APY, Risk Level: ${y}/10`;
          }
        }
      },
    },
    scales: {
      y: {
        title: {
          display: true,
          text: 'Risk Level (1-10)',
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
        },
        min: 0,
        max: 10,
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
          stepSize: 1,
        },
      },
      x: {
        title: {
          display: true,
          text: 'Expected APY (%)',
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
        },
        min: 0,
        max: 10,
        grid: {
          color: 'rgba(75, 85, 99, 0.3)', // gray-600 with opacity
        },
        ticks: {
          color: 'rgba(209, 213, 219, 1)', // text-gray-300
        },
      },
    },
  };

  // Calculate portfolio risk score (1-100)
  const riskScore = 48; // Medium risk
  const riskLevel = riskScore < 33 ? 'Low' : riskScore < 66 ? 'Medium' : 'High';
  const riskColor = riskScore < 33 ? 'green' : riskScore < 66 ? 'yellow' : 'red';

  // Risk breakdown by strategy
  const riskBreakdown = [
    { strategy: 'High-Yield Strategy', allocation: 30, riskContribution: 47, riskLevel: 'High' },
    { strategy: 'Balanced Strategy', allocation: 45, riskContribution: 42, riskLevel: 'Medium' },
    { strategy: 'Stable-Yield Strategy', allocation: 25, riskContribution: 11, riskLevel: 'Low' },
  ];

  return (
    <div className="bg-gray-800 rounded-xl shadow-lg border border-gray-700 overflow-hidden">
      <div className="p-5">
        <h2 className="text-xl font-bold text-white mb-4">Risk Assessment</h2>
        
        {/* Risk Score Meter */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700 col-span-1">
            <p className="text-gray-400 text-sm mb-1">Portfolio Risk Score</p>
            <div className="flex items-center">
              <p className="text-2xl font-bold text-white">{riskScore}/100</p>
              <span className={`ml-2 px-2 py-1 text-xs rounded ${
                riskLevel === 'Low' ? 'bg-green-900/50 text-green-400' : 
                riskLevel === 'Medium' ? 'bg-yellow-900/50 text-yellow-400' : 
                'bg-red-900/50 text-red-400'
              }`}>
                {riskLevel} Risk
              </span>
            </div>
            
            {/* Risk meter visualization */}
            <div className="mt-3 w-full bg-gray-700 rounded-full h-4">
              <div 
                className={`h-4 rounded-full ${
                  riskLevel === 'Low' ? 'bg-green-500' : 
                  riskLevel === 'Medium' ? 'bg-yellow-500' : 
                  'bg-red-500'
                }`}
                style={{ width: `${riskScore}%` }}
              ></div>
            </div>
            <div className="flex justify-between mt-1 text-xs text-gray-400">
              <span>Low Risk</span>
              <span>Medium</span>
              <span>High Risk</span>
            </div>
          </div>
          
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-700 col-span-2">
            <p className="text-gray-400 text-sm mb-2">Risk Assessment Summary</p>
            <p className="text-gray-300 text-sm mb-3">
              Your portfolio has a <span className={
                riskLevel === 'Low' ? 'text-green-400' : 
                riskLevel === 'Medium' ? 'text-yellow-400' : 
                'text-red-400'
              }>{riskLevel.toLowerCase()} risk level</span>, which aligns with your selected risk tolerance. 
              NapFi AI has optimized your asset allocation to balance risk and return.
            </p>
            <ul className="list-disc list-inside text-gray-300 text-sm space-y-1">
              <li>Diversification across strategies reduces overall portfolio risk</li>
              <li>Current market volatility is <span className="text-yellow-400">moderate</span></li>
              <li>AI recommendation: Maintain current risk profile</li>
            </ul>
          </div>
        </div>
        
        {/* Risk-Reward Scatter Plot */}
        <div className="bg-gray-900 rounded-lg p-4 border border-gray-700 mb-6">
          <div style={{ height: '300px' }}>
            <Scatter data={scatterData} options={scatterOptions} />
          </div>
        </div>
        
        {/* Risk Breakdown Table */}
        <div className="mb-6">
          <h3 className="text-lg font-semibold text-white mb-3">Risk Contribution by Strategy</h3>
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
                    Risk Level
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Risk Contribution
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Visualization
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-700">
                {riskBreakdown.map((item, index) => (
                  <tr key={index}>
                    <td className="px-4 py-3 text-sm text-gray-200">{item.strategy}</td>
                    <td className="px-4 py-3 text-sm text-gray-200">{item.allocation}%</td>
                    <td className="px-4 py-3 text-sm">
                      <span className={`px-2 py-1 text-xs rounded ${
                        item.riskLevel === 'Low' ? 'bg-green-900/50 text-green-400' : 
                        item.riskLevel === 'Medium' ? 'bg-yellow-900/50 text-yellow-400' : 
                        'bg-red-900/50 text-red-400'
                      }`}>
                        {item.riskLevel}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-200">{item.riskContribution}%</td>
                    <td className="px-4 py-3 text-sm">
                      <div className="w-full bg-gray-700 rounded-full h-2">
                        <div 
                          className={`h-2 rounded-full ${
                            item.riskLevel === 'Low' ? 'bg-green-500' : 
                            item.riskLevel === 'Medium' ? 'bg-yellow-500' : 
                            'bg-red-500'
                          }`}
                          style={{ width: `${item.riskContribution}%` }}
                        ></div>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
        
        {/* Risk Management Recommendations */}
        <div className="bg-blue-900/30 border border-blue-800 rounded-lg p-4">
          <h3 className="text-lg font-semibold text-blue-300 mb-2">AI Risk Management Insights</h3>
          <p className="text-gray-300 text-sm mb-3">
            Based on current market conditions and your risk profile, NapFi AI recommends:
          </p>
          <ul className="list-disc list-inside text-gray-300 text-sm space-y-1">
            <li>Your current risk level is appropriate for your stated investment goals</li>
            <li>Consider increasing allocation to Stable-Yield Strategy by 5% if seeking lower volatility</li>
            <li>Market stress test shows your portfolio can withstand a 15% market correction with minimal impact</li>
            <li>Diversification score: <span className="text-green-400 font-semibold">85/100</span> (Well diversified)</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default RiskAssessment;
