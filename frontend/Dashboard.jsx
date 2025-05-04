import React, { useState, useEffect } from 'react';
import { useAccount, useContractRead } from 'wagmi';
import MCPDecisionCard from './MCPDecisionCard';
import AIDecisionModuleABI from '../abi/AIDecisionModule.json';

/**
 * Dashboard component that displays user's portfolio and the latest MCP decision
 */
const Dashboard = ({ aiDecisionModuleAddress }) => {
  const { address, isConnected } = useAccount();
  const [latestDecisionId, setLatestDecisionId] = useState(null);
  
  // In a real implementation, we would fetch the latest decision ID from an event or API
  // For the hackathon demo, we'll use a mock decision ID
  useEffect(() => {
    if (isConnected) {
      // This would typically come from listening to events or an API call
      const mockDecisionId = '0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234';
      setLatestDecisionId(mockDecisionId);
    }
  }, [isConnected]);

  return (
    <div className="dashboard-container">
      <div className="dashboard-header">
        <h1>NapFi AI Dashboard</h1>
        <p className="user-address">
          Connected: {isConnected ? `${address.slice(0, 6)}...${address.slice(-4)}` : 'Not connected'}
        </p>
      </div>
      
      <div className="dashboard-content">
        <div className="portfolio-section">
          <h2>Your Portfolio</h2>
          <div className="portfolio-stats">
            <div className="stat-card">
              <h3>Total Value</h3>
              <p className="stat-value">$10,245.67</p>
              <p className="stat-change positive">+2.4% (24h)</p>
            </div>
            <div className="stat-card">
              <h3>Current APY</h3>
              <p className="stat-value">4.2%</p>
              <p className="stat-change positive">+0.3% from last week</p>
            </div>
            <div className="stat-card">
              <h3>Risk Score</h3>
              <p className="stat-value">3.5/10</p>
              <p className="stat-info">Moderate</p>
            </div>
          </div>
          
          <div className="allocation-chart">
            <h3>Current Allocation</h3>
            <div className="chart-placeholder">
              {/* In a real implementation, this would be a chart component */}
              <div className="mock-chart">
                <div className="chart-segment aave" style={{ width: '70%' }}>Aave: 70%</div>
                <div className="chart-segment compound" style={{ width: '30%' }}>Compound: 30%</div>
              </div>
            </div>
          </div>
        </div>
        
        <div className="ai-decision-section">
          <h2>AI Decision Insights</h2>
          <p className="section-description">
            Understand why NapFi AI has allocated your funds this way
          </p>
          
          {latestDecisionId ? (
            <MCPDecisionCard 
              decisionId={latestDecisionId} 
              aiDecisionModuleAddress={aiDecisionModuleAddress} 
            />
          ) : (
            <div className="no-decision-card">
              <p>No allocation decisions have been made yet.</p>
            </div>
          )}
          
          <div className="decision-history">
            <h3>Decision History</h3>
            <ul className="history-list">
              <li className="history-item">
                <span className="history-date">May 1, 2025</span>
                <span className="history-action">Initial allocation</span>
                <button className="view-button">View</button>
              </li>
              <li className="history-item">
                <span className="history-date">May 15, 2025</span>
                <span className="history-action">Rebalance due to market change</span>
                <button className="view-button">View</button>
              </li>
              <li className="history-item">
                <span className="history-date">June 1, 2025</span>
                <span className="history-action">Added new strategy</span>
                <button className="view-button">View</button>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;

// CSS for the component (would typically be in a separate file)
const styles = `
.dashboard-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  font-family: 'Inter', sans-serif;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

.dashboard-header h1 {
  font-size: 28px;
  color: #333;
  margin: 0;
}

.user-address {
  background: #f0f0f0;
  padding: 8px 16px;
  border-radius: 20px;
  font-family: monospace;
  font-size: 14px;
}

.dashboard-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
}

@media (max-width: 768px) {
  .dashboard-content {
    grid-template-columns: 1fr;
  }
}

.portfolio-section, .ai-decision-section {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  padding: 24px;
}

.portfolio-section h2, .ai-decision-section h2 {
  margin-top: 0;
  margin-bottom: 16px;
  font-size: 22px;
  color: #333;
}

.section-description {
  color: #666;
  margin-bottom: 20px;
}

.portfolio-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
  margin-bottom: 30px;
}

.stat-card {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 16px;
  text-align: center;
}

.stat-card h3 {
  font-size: 14px;
  color: #666;
  margin-top: 0;
  margin-bottom: 8px;
}

.stat-value {
  font-size: 24px;
  font-weight: 700;
  margin: 0;
  color: #333;
}

.stat-change {
  font-size: 14px;
  margin: 8px 0 0;
}

.stat-change.positive {
  color: #28a745;
}

.stat-change.negative {
  color: #dc3545;
}

.stat-info {
  font-size: 14px;
  margin: 8px 0 0;
  color: #666;
}

.allocation-chart {
  margin-top: 20px;
}

.allocation-chart h3 {
  font-size: 18px;
  margin-bottom: 16px;
}

.mock-chart {
  height: 40px;
  display: flex;
  border-radius: 6px;
  overflow: hidden;
}

.chart-segment {
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 600;
  font-size: 14px;
}

.chart-segment.aave {
  background: #0066cc;
}

.chart-segment.compound {
  background: #6610f2;
}

.decision-history {
  margin-top: 30px;
}

.decision-history h3 {
  font-size: 18px;
  margin-bottom: 16px;
}

.history-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.history-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #eee;
}

.history-date {
  font-size: 14px;
  color: #666;
  width: 100px;
}

.history-action {
  flex: 1;
  font-size: 14px;
}

.view-button {
  background: #f0f0f0;
  border: none;
  border-radius: 4px;
  padding: 6px 12px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.2s;
}

.view-button:hover {
  background: #e0e0e0;
}

.no-decision-card {
  background: #f8f9fa;
  border-radius: 12px;
  padding: 30px;
  text-align: center;
  color: #666;
}
`;
