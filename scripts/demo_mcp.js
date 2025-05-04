// Demo script for MCP integration
const { ethers } = require('ethers');
const crypto = require('crypto');

// This script demonstrates how the MCP integration would be used in a real-world scenario
// For the hackathon, we'll use hardcoded values and mock signatures

// Sample decision data
const sampleDecisions = [
  {
    id: "decision_001",
    strategies: [
      "0x1111111111111111111111111111111111111111", // Aave strategy
      "0x2222222222222222222222222222222222222222"  // Compound strategy
    ],
    allocations: [7000, 3000], // 70% Aave, 30% Compound
    reasoning: "Aave currently offers a higher APY (4.2% vs 3.1%) with similar risk profile. Market conditions favor lending protocols with larger liquidity pools, making Aave a more stable option in the current environment."
  },
  {
    id: "decision_002",
    strategies: [
      "0x1111111111111111111111111111111111111111", // Aave strategy
      "0x2222222222222222222222222222222222222222"  // Compound strategy
    ],
    allocations: [4000, 6000], // 40% Aave, 60% Compound
    reasoning: "Compound's APY has increased to 4.5% while Aave remains at 4.2%. Additionally, Compound has implemented new security measures, reducing its risk score. The higher allocation to Compound balances higher returns with acceptable risk."
  },
  {
    id: "decision_003",
    strategies: [
      "0x1111111111111111111111111111111111111111", // Aave strategy
      "0x2222222222222222222222222222222222222222", // Compound strategy
      "0x3333333333333333333333333333333333333333"  // Curve strategy
    ],
    allocations: [3000, 4000, 3000], // 30% Aave, 40% Compound, 30% Curve
    reasoning: "Adding Curve to the strategy mix provides better diversification. While Curve's APY is slightly lower at 3.8%, it offers exposure to different market segments. This three-way allocation optimizes for both yield and risk through diversification."
  }
];

// Mock function to generate a signature (in a real implementation, this would use a private key)
function generateMockSignature(decisionId, strategies, allocations, reasoning) {
  const message = decisionId + strategies.join('') + allocations.join('') + reasoning;
  return '0x' + crypto.createHash('sha256').update(message).digest('hex');
}

// Function to simulate updating allocations with MCP
async function updateAllocationsWithMCP(aiDecisionModule, decisionData, oracleWallet) {
  const { id, strategies, allocations, reasoning } = decisionData;
  
  // Convert decision ID to bytes32
  const decisionId = ethers.utils.id(id);
  
  // Generate mock signature
  const signature = generateMockSignature(id, strategies, allocations, reasoning);
  
  console.log(`\n--- Updating Allocations with MCP ---`);
  console.log(`Decision ID: ${id}`);
  console.log(`Strategies: ${strategies.join(', ')}`);
  console.log(`Allocations: ${allocations.map(a => a/100 + '%').join(', ')}`);
  console.log(`Reasoning: ${reasoning}`);
  console.log(`Signature: ${signature.substring(0, 10)}...`);
  
  // In a real implementation, this would call the contract
  console.log(`\nCalling aiDecisionModule.updateAllocationsWithMCP()`);
  
  // Simulate contract call
  /*
  const tx = await aiDecisionModule.connect(oracleWallet).updateAllocationsWithMCP(
    decisionId,
    strategies,
    allocations,
    reasoning,
    signature
  );
  await tx.wait();
  console.log(`Transaction hash: ${tx.hash}`);
  */
  
  // For demo, just show the expected result
  console.log(`✅ Allocation updated successfully!`);
  console.log(`✅ Decision recorded on-chain with reasoning`);
  
  return decisionId;
}

// Function to simulate retrieving decision data
async function getDecisionData(aiDecisionModule, decisionId) {
  console.log(`\n--- Retrieving Decision Data ---`);
  console.log(`Decision ID: ${decisionId}`);
  
  // In a real implementation, this would call the contract
  console.log(`\nCalling aiDecisionModule.getDecision()`);
  
  // For demo, just show the expected result
  const decision = sampleDecisions.find(d => ethers.utils.id(d.id) === decisionId);
  
  console.log(`\nDecision Data Retrieved:`);
  console.log(`Timestamp: ${new Date().toISOString()}`);
  console.log(`Reasoning: ${decision.reasoning}`);
  console.log(`Strategies: ${decision.strategies.join(', ')}`);
  console.log(`Allocations: ${decision.allocations.map(a => a/100 + '%').join(', ')}`);
}

// Main demo function
async function runMCPDemo() {
  console.log("=== NapFi AI - MCP Integration Demo ===");
  console.log("This demo shows how the Model Context Protocol integration");
  console.log("provides transparency for AI-driven allocation decisions.\n");
  
  // In a real implementation, these would be actual contract instances and wallets
  const mockAIDecisionModule = {};
  const mockOracleWallet = {};
  
  // Demo scenario 1: Initial allocation
  console.log("SCENARIO 1: INITIAL ALLOCATION");
  const decisionId1 = await updateAllocationsWithMCP(
    mockAIDecisionModule,
    sampleDecisions[0],
    mockOracleWallet
  );
  
  // Retrieve and display the decision
  await getDecisionData(mockAIDecisionModule, decisionId1);
  
  // Demo scenario 2: Market conditions change
  console.log("\n\nSCENARIO 2: MARKET CONDITIONS CHANGE");
  console.log("Two weeks later, market conditions have changed...");
  const decisionId2 = await updateAllocationsWithMCP(
    mockAIDecisionModule,
    sampleDecisions[1],
    mockOracleWallet
  );
  
  // Retrieve and display the decision
  await getDecisionData(mockAIDecisionModule, decisionId2);
  
  // Demo scenario 3: New strategy added
  console.log("\n\nSCENARIO 3: NEW STRATEGY ADDED");
  console.log("A month later, a new strategy is added to the protocol...");
  const decisionId3 = await updateAllocationsWithMCP(
    mockAIDecisionModule,
    sampleDecisions[2],
    mockOracleWallet
  );
  
  // Retrieve and display the decision
  await getDecisionData(mockAIDecisionModule, decisionId3);
  
  console.log("\n=== Demo Complete ===");
  console.log("The MCP integration allows users to understand why");
  console.log("their funds are allocated in specific ways, building");
  console.log("trust in the AI-driven decision making process.");
}

// In a real implementation, this would be executed when the script is run
// runMCPDemo().catch(console.error);

// For the hackathon demo, this script can be copied and pasted into a console
// or run directly with Node.js
console.log("To run the demo: runMCPDemo()");

module.exports = {
  runMCPDemo
};
