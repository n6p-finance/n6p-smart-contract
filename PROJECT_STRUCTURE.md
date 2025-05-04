# NapFi AI Project Structure

This document outlines the project structure for NapFi AI, using Foundry for smart contract development and Next.js for the frontend.

## Repository Structure

```
napfi_ai/
├── ROADMAP.md                # Project roadmap
├── MILESTONES.md             # Detailed milestone checklist
├── PROJECT_STRUCTURE.md      # This document
├── contracts/                # Foundry project for smart contracts
│   ├── .gitignore
│   ├── foundry.toml          # Foundry configuration
│   ├── lib/                  # Dependencies (managed by forge)
│   ├── script/               # Deployment and interaction scripts
│   │   ├── Deploy.s.sol      # Deployment script
│   │   └── Interaction.s.sol # Contract interaction scripts
│   ├── src/                  # Smart contract source code
│   │   ├── interfaces/       # Contract interfaces
│   │   ├── core/             # Core protocol contracts
│   │   ├── strategies/       # Yield strategy implementations
│   │   ├── utils/            # Utility contracts and libraries
│   │   └── NapFiAI.sol       # Main contract entry point
│   └── test/                 # Contract tests
│       ├── unit/             # Unit tests
│       ├── integration/      # Integration tests
│       └── fork/             # Forked network tests
├── frontend/                 # Next.js frontend application
│   ├── .gitignore
│   ├── package.json          # NPM dependencies
│   ├── next.config.js        # Next.js configuration
│   ├── public/               # Static assets
│   ├── src/                  # Frontend source code
│   │   ├── app/              # Next.js App Router
│   │   ├── components/       # React components
│   │   │   ├── ui/           # UI components
│   │   │   ├── dashboard/    # Dashboard components
│   │   │   └── forms/        # Form components
│   │   ├── hooks/            # Custom React hooks
│   │   ├── contexts/         # React contexts
│   │   ├── services/         # API and service integrations
│   │   ├── utils/            # Utility functions
│   │   ├── types/            # TypeScript type definitions
│   │   └── styles/           # CSS and styling
│   └── tests/                # Frontend tests
└── scripts/                  # Development and deployment scripts
    ├── setup.sh              # Project setup script
    └── deploy.sh             # Deployment automation
```

## Smart Contract Architecture (Foundry)

### Core Contracts

1. **Vault.sol**
   - Main entry point for user deposits
   - Manages shares and accounting
   - Delegates to Controller for strategy allocation

2. **Controller.sol**
   - Manages strategy selection and fund allocation
   - Implements rebalancing logic
   - Connects to AI decision module

3. **StrategyRegistry.sol**
   - Maintains registry of available strategies
   - Handles strategy approval and removal
   - Tracks strategy performance metrics

4. **AIDecisionModule.sol**
   - On-chain component for strategy selection
   - Receives data from off-chain AI system
   - Makes allocation decisions based on parameters

### Strategy Contracts

1. **IStrategy.sol**
   - Interface for all strategy implementations
   - Defines required functions for strategies

2. **BaseStrategy.sol**
   - Abstract base contract for strategies
   - Implements common functionality

3. **Protocol-specific strategies**
   - AaveStrategy.sol
   - CompoundStrategy.sol
   - CurveStrategy.sol
   - ConvexStrategy.sol
   - UniswapV3Strategy.sol

### Utility Contracts

1. **PriceOracle.sol**
   - Provides price data for assets
   - Integrates with Chainlink or other oracles

2. **YieldOracle.sol**
   - Tracks and provides yield data for protocols

3. **SecurityModule.sol**
   - Implements security features
   - Handles emergency situations

## Frontend Architecture (Next.js)

### Pages

1. **Dashboard**
   - Overview of user portfolio
   - Performance metrics
   - Current allocations

2. **Deposit/Withdraw**
   - Interface for depositing assets
   - Interface for withdrawing assets
   - Transaction status tracking

3. **Strategy Explorer**
   - View available strategies
   - Performance comparison
   - Risk assessment

4. **Settings**
   - User preferences
   - Risk profile configuration
   - Notification settings

### Key Components

1. **Web3 Integration**
   - Wallet connection (using wagmi/viem)
   - Contract interaction
   - Transaction management

2. **Data Visualization**
   - Charts and graphs for performance
   - Allocation visualization
   - Risk representation

3. **Notifications**
   - Transaction alerts
   - Performance updates
   - Security notifications

## Development Workflow

### Smart Contract Development (Foundry)

1. **Setup**
   ```bash
   cd contracts
   forge init
   forge install OpenZeppelin/openzeppelin-contracts
   ```

2. **Testing**
   ```bash
   forge test
   forge coverage
   ```

3. **Deployment**
   ```bash
   forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
   ```

### Frontend Development (Next.js)

1. **Setup**
   ```bash
   cd frontend
   npm install
   ```

2. **Development**
   ```bash
   npm run dev
   ```

3. **Testing**
   ```bash
   npm test
   ```

4. **Building**
   ```bash
   npm run build
   ```

## CI/CD Pipeline

1. **Smart Contract CI**
   - Run tests on PR
   - Check code coverage
   - Static analysis with Slither

2. **Frontend CI**
   - Run tests on PR
   - Lint code
   - Build check

3. **Deployment CD**
   - Deploy contracts to testnet on merge to develop
   - Deploy contracts to mainnet on merge to main
   - Deploy frontend to Vercel/Netlify

## Development Standards

### Smart Contracts

- Follow Solidity style guide
- Use NatSpec comments
- Comprehensive test coverage (>95%)
- Security-first approach

### Frontend

- TypeScript for type safety
- Component-based architecture
- Responsive design
- Accessibility compliance

## Security Considerations

1. **Smart Contract Security**
   - Multiple external audits
   - Formal verification where possible
   - Bug bounty program
   - Gradual rollout with caps

2. **Frontend Security**
   - Regular dependency audits
   - CSP implementation
   - Input validation
   - Secure authentication

---

This structure will evolve as the project progresses, but provides a solid foundation for development using Foundry and Next.js.
