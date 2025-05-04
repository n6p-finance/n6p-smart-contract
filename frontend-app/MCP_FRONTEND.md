# Model Context Protocol (MCP) Frontend Integration

This document outlines the integration of Model Context Protocol (MCP) components into the NapFi AI frontend application.

## Overview

The Model Context Protocol integration provides transparency and verifiability to AI-driven allocation decisions in the NapFi AI protocol. The frontend components allow users to:

1. View AI allocation decisions and their reasoning
2. Verify the authenticity of decisions through cryptographic signatures
3. Understand why their funds are allocated in specific ways

## Components

### 1. MCPDecisionCard

Located at: `/src/components/mcp/MCPDecisionCard.tsx`

This component displays:
- Decision reasoning provided by the AI
- Current allocation percentages across strategies
- Timestamp of when the decision was made
- Link to verify the decision's authenticity

### 2. MCPVerification

Located at: `/src/components/mcp/MCPVerification.tsx`

This component allows users to:
- Verify the cryptographic signature of an AI decision
- Confirm that a decision was made by the authorized AI system
- Ensure the decision has not been tampered with

### 3. Verification Page

Located at: `/src/app/verify/page.tsx`

A dedicated page for verifying decision authenticity, which:
- Accepts decision IDs and signatures via URL parameters
- Provides a form for manual verification
- Explains the importance of MCP verification

## Web3 Integration

The MCP components interact with the blockchain through:

- `wagmi` for React hooks to read blockchain data
- `@rainbow-me/rainbowkit` for wallet connection
- Contract ABIs located in `/src/abi/`

## Usage

### Displaying Decision Reasoning

```tsx
import MCPDecisionCard from '@/components/mcp/MCPDecisionCard';

// In your component
<MCPDecisionCard decisionId="0x123..." />
```

### Verifying Decisions

```tsx
import MCPVerification from '@/components/mcp/MCPVerification';

// In your component
<MCPVerification 
  decisionId="0x123..." 
  signature="0xabc..." 
/>
```

## Future Enhancements

1. Real-time decision updates via event subscriptions
2. Historical decision analytics and performance tracking
3. Enhanced visualization of allocation changes over time
4. Integration with additional MCP features as they are developed

## Related Documentation

- [MCP Implementation Plan](/MCP_IMPLEMENTATION.md)
- [Smart Contract Documentation](/contracts/README.md)
