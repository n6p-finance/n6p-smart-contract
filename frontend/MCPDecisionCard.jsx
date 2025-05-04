import React, { useState, useEffect } from 'react';
import { useContractRead } from 'wagmi';
import { formatEther } from 'ethers/lib/utils';
import AIDecisionModuleABI from '../abi/AIDecisionModule.json';

/**
 * Component to display MCP decision reasoning
 * This would be used in the dashboard to show users why their funds are allocated in a specific way
 */
const MCPDecisionCard = ({ decisionId, aiDecisionModuleAddress }) => {
  const [decision, setDecision] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Read decision data from the contract
  const { data, isLoading, isError } = useContractRead({
    address: aiDecisionModuleAddress,
    abi: AIDecisionModuleABI,
    functionName: 'getDecision',
    args: [decisionId],
    enabled: !!decisionId && !!aiDecisionModuleAddress,
  });

  useEffect(() => {
    if (isLoading) {
      setLoading(true);
      return;
    }

    if (isError) {
      setLoading(false);
      setError('Failed to load decision data');
      return;
    }

    if (data) {
      const [id, timestamp, reasoning, strategies, allocations, signature] = data;
      
      // Format the data for display
      const formattedDecision = {
        id,
        timestamp: new Date(timestamp.toNumber() * 1000).toLocaleString(),
        reasoning,
        strategies,
        allocations: allocations.map(a => `${(a.toNumber() / 100).toFixed(1)}%`),
        signature: signature.slice(0, 10) + '...'
      };
      
      setDecision(formattedDecision);
      setLoading(false);
    }
  }, [data, isLoading, isError]);

  // Render loading state
  if (loading) {
    return (
      <div className="mcp-decision-card mcp-loading">
        <div className="mcp-card-header">
          <h3>AI Decision Reasoning</h3>
        </div>
        <div className="mcp-card-body">
          <p>Loading decision data...</p>
        </div>
      </div>
    );
  }

  // Render error state
  if (error) {
    return (
      <div className="mcp-decision-card mcp-error">
        <div className="mcp-card-header">
          <h3>AI Decision Reasoning</h3>
        </div>
        <div className="mcp-card-body">
          <p>Error: {error}</p>
        </div>
      </div>
    );
  }

  // Render decision data
  return (
    <div className="mcp-decision-card">
      <div className="mcp-card-header">
        <h3>AI Decision Reasoning</h3>
        <span className="mcp-timestamp">{decision?.timestamp}</span>
      </div>
      <div className="mcp-card-body">
        <div className="mcp-reasoning">
          <h4>Why this allocation?</h4>
          <p>{decision?.reasoning || 'No reasoning provided'}</p>
        </div>
        <div className="mcp-allocations">
          <h4>Current Allocation</h4>
          <ul>
            {decision?.strategies.map((strategy, index) => (
              <li key={strategy}>
                <span className="strategy-address">{strategy.slice(0, 6)}...{strategy.slice(-4)}</span>
                <span className="strategy-allocation">{decision.allocations[index]}</span>
              </li>
            ))}
          </ul>
        </div>
        <div className="mcp-verification">
          <h4>Verification</h4>
          <p>Decision ID: {decision?.id}</p>
          <p>Signature: {decision?.signature}</p>
          <button className="verify-button">Verify Decision</button>
        </div>
      </div>
    </div>
  );
};

export default MCPDecisionCard;

// CSS for the component (would typically be in a separate file)
const styles = `
.mcp-decision-card {
  background: #f8f9fa;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  margin: 20px 0;
  overflow: hidden;
  transition: all 0.3s ease;
}

.mcp-decision-card:hover {
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}

.mcp-card-header {
  background: #0066cc;
  color: white;
  padding: 16px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.mcp-card-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.mcp-timestamp {
  font-size: 14px;
  opacity: 0.8;
}

.mcp-card-body {
  padding: 20px;
}

.mcp-reasoning, .mcp-allocations, .mcp-verification {
  margin-bottom: 20px;
}

.mcp-reasoning h4, .mcp-allocations h4, .mcp-verification h4 {
  font-size: 16px;
  margin-bottom: 8px;
  color: #333;
}

.mcp-reasoning p {
  line-height: 1.6;
  color: #555;
}

.mcp-allocations ul {
  list-style: none;
  padding: 0;
}

.mcp-allocations li {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #eee;
}

.strategy-address {
  font-family: monospace;
  color: #666;
}

.strategy-allocation {
  font-weight: bold;
  color: #0066cc;
}

.verify-button {
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 8px 16px;
  cursor: pointer;
  font-weight: 600;
  transition: background 0.2s;
}

.verify-button:hover {
  background: #218838;
}

.mcp-loading, .mcp-error {
  min-height: 200px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.mcp-error {
  background: #fff8f8;
}

.mcp-error p {
  color: #dc3545;
}
`;
