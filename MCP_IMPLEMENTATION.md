# Model Context Protocol (MCP) Implementation Plan

This document outlines the technical implementation plan for integrating a simplified version of the Model Context Protocol (MCP) into the NapFi AI project for the hackathon.

## 1. MCP Oracle Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMCPOracle {
    /**
     * @dev Submit a query to the MCP Oracle
     * @param query Encoded query data
     * @return response Encoded response data
     */
    function query(bytes memory query) external view returns (bytes memory response);
    
    /**
     * @dev Verify the signature of an AI decision
     * @param message The message that was signed
     * @param signature The signature to verify
     * @return True if the signature is valid
     */
    function verifySignature(bytes memory message, bytes memory signature) external view returns (bool);
}
```

## 2. MCP Data Structures

```solidity
// Add to AIDecisionModule.sol

// Structure to store AI decisions with reasoning
struct MCPDecision {
    bytes32 decisionId;          // Unique identifier for the decision
    uint256 timestamp;           // When the decision was made
    string reasoning;            // Human-readable explanation
    address[] strategies;        // Affected strategies
    uint256[] allocations;       // New allocations
    bytes signature;             // Cryptographic proof
}

// Mapping to store decision history
mapping(bytes32 => MCPDecision) public aiDecisions;
```

## 3. AIDecisionModule Modifications

```solidity
// Add to AIDecisionModule.sol

// MCP Oracle reference
IMCPOracle public mcpOracle;

/**
 * @dev Set the MCP Oracle address
 * @param _oracle Address of the MCP Oracle
 */
function setMCPOracle(address _oracle) external onlyOwner {
    mcpOracle = IMCPOracle(_oracle);
}

/**
 * @dev Update allocations using MCP
 * @param decisionId Unique identifier for this decision
 * @param _strategies Array of strategy addresses
 * @param _allocations Array of allocation percentages (in basis points)
 * @param reasoning Human-readable explanation for the allocation change
 * @param signature Cryptographic proof of the decision
 */
function updateAllocationsWithMCP(
    bytes32 decisionId,
    address[] calldata _strategies,
    uint256[] calldata _allocations,
    string calldata reasoning,
    bytes calldata signature
) external onlyOracle {
    // Verify signature if oracle is set
    if (address(mcpOracle) != address(0)) {
        bytes memory message = abi.encodePacked(decisionId, _strategies, _allocations, reasoning);
        require(mcpOracle.verifySignature(message, signature), "Invalid MCP signature");
    }
    
    // Store the decision
    aiDecisions[decisionId] = MCPDecision({
        decisionId: decisionId,
        timestamp: block.timestamp,
        reasoning: reasoning,
        strategies: _strategies,
        allocations: _allocations,
        signature: signature
    });
    
    // Update allocations in the controller
    if (address(controller) != address(0)) {
        controller.updateAllocations(_strategies, _allocations);
    }
    
    emit AllocationUpdated(decisionId, reasoning);
}

/**
 * @dev Get the reasoning behind a specific allocation decision
 * @param decisionId The ID of the decision to query
 * @return The human-readable reasoning
 */
function getDecisionReasoning(bytes32 decisionId) external view returns (string memory) {
    return aiDecisions[decisionId].reasoning;
}
```

## 4. Mock MCP Oracle Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IMCPOracle.sol";

/**
 * @title MockMCPOracle
 * @dev A simplified mock implementation of an MCP Oracle for the hackathon
 */
contract MockMCPOracle is IMCPOracle {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Mock implementation of query function
     * @param query Encoded query data
     * @return Encoded response data
     */
    function query(bytes memory query) external view override returns (bytes memory) {
        // For the hackathon, we'll just return a mock response
        // In a real implementation, this would call an off-chain AI service
        
        // Decode the query to determine what's being asked
        string memory queryType = abi.decode(query, (string));
        
        if (keccak256(abi.encodePacked(queryType)) == keccak256(abi.encodePacked("get_optimal_allocations"))) {
            // Mock optimal allocations response
            address[] memory strategies = new address[](2);
            uint256[] memory allocations = new uint256[](2);
            
            // These would be dynamically determined in a real implementation
            strategies[0] = address(0x1234...); // Example address
            strategies[1] = address(0x5678...); // Example address
            allocations[0] = 7000; // 70%
            allocations[1] = 3000; // 30%
            
            return abi.encode(strategies, allocations);
        }
        
        // Default empty response
        return "";
    }
    
    /**
     * @dev Mock implementation of signature verification
     * @param message The message that was signed
     * @param signature The signature to verify
     * @return Always returns true for the hackathon demo
     */
    function verifySignature(bytes memory message, bytes memory signature) external view override returns (bool) {
        // For the hackathon, we'll just return true
        // In a real implementation, this would verify the cryptographic signature
        return true;
    }
}
```

## 5. Frontend Integration

For the hackathon, we'll add a simple UI component to display the AI decision reasoning:

```typescript
// React component example
const AIDecisionDisplay = ({ decisionId }) => {
  const [reasoning, setReasoning] = useState("");
  
  useEffect(() => {
    const fetchReasoning = async () => {
      const aiDecisionModule = new ethers.Contract(
        aiDecisionModuleAddress,
        aiDecisionModuleABI,
        provider
      );
      
      const reasoning = await aiDecisionModule.getDecisionReasoning(decisionId);
      setReasoning(reasoning);
    };
    
    if (decisionId) {
      fetchReasoning();
    }
  }, [decisionId]);
  
  return (
    <div className="ai-decision-card">
      <h3>AI Decision Reasoning</h3>
      <p>{reasoning || "No reasoning available for this decision"}</p>
    </div>
  );
};
```

## 6. Testing Strategy

For the MCP integration, we'll add the following tests:

1. **Unit Tests**:
   - Test setting/updating the MCP Oracle
   - Test storing and retrieving AI decisions
   - Test signature verification (mock)

2. **Integration Tests**:
   - Test the full flow from AI decision to allocation update
   - Test the interaction between AIDecisionModule and Controller with MCP

## 7. Hackathon Implementation Timeline

### Day 1 (4 hours):
- Create the IMCPOracle interface
- Implement the MockMCPOracle contract
- Add MCP data structures to AIDecisionModule

### Day 2 (4 hours):
- Modify AIDecisionModule to use MCP
- Implement decision storage and verification
- Write basic tests for MCP functionality

### Day 3 (2 hours):
- Add frontend component to display decision reasoning
- Create a demo script to showcase MCP integration

## 8. Future Enhancements (Post-Hackathon)

1. **Real AI Integration**: Connect to an actual AI model that follows MCP standards
2. **Enhanced Verification**: Implement proper cryptographic verification of AI decisions
3. **Historical Analysis**: Allow users to browse past decisions and their outcomes
4. **Feedback Loop**: Allow the AI to learn from the performance of its allocation decisions
