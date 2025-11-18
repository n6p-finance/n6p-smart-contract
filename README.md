
# NapFi Smart Contracts

NapFi is an AI-powered decentralized finance (DeFi) and creative finance protocol built on Optimism.
It provides smart contracts that allow users to deposit assets, earn optimized yields, and participate in creative vaults for tokenized assets such as music, art, or other creative projects.

---
**Deployment to Base Sepolia = https://sepolia.basescan.org/address/0x2340F9643C18CEbfd7b6042AD8e23B205B286D78#code**
---
**Deployment Details:**
---
 **Deployment Addresses**
  Registry: 0x2340F9643C18CEbfd7b6042AD8e23B205B286D78                                                                                                                                               
  Vault DeFi Implementation: 0x11761e6bDef98e8fa7216dEe36068eD922B24Aaa

 **Configuration** 
  Governance: 0x005684aC7C737Bff821ECCb377cC46e5A7dcB60D                                                                                                                                             
  Management: 0x005684aC7C737Bff821ECCb377cC46e5A7dcB60D                                                                                                                                             
  Guardian: 0x005684aC7C737Bff821ECCb377cC46e5A7dcB60D                                                                                                                                               
  Rewards: 0x005684aC7C737Bff821ECCb377cC46e5A7dcB60D

---

### Overview

NapFi automates yield generation through modular vault and strategy contracts.
It is designed to connect with an off-chain AI engine that analyzes yield data and suggests the most efficient strategy routes based on current market conditions and protocol risk levels.

The goal of NapFi is to combine intelligent DeFi yield optimization with creative asset tokenization — forming a bridge between financial automation and the creative economy.

---

### Core Features

1. **Smart Vaults** – A modular vault system that manages user deposits, withdrawals, and yield strategies.
2. **AI-Powered Allocation** – The off-chain AI engine provides data-driven strategy recommendations.
3. **Multi-Protocol Compatibility** – Supports integrations with protocols like Aave, Compound, and Curve.
4. **Creative Vaults (Phase 2)** – Tokenization of music or art using ERC-1155 and royalty payments via ERC-2981.
5. **Upgradeable Architecture** – Built with OpenZeppelin for safety and future extensibility.
6. **Optimized for L2** – Deployed on Optimism, Base, and Polygon to ensure low transaction costs and high efficiency.

---

### Architecture

Diagram of UnifiedVault.sol:
<img width="1257" height="2564" alt="778ab1ca-b454-410f-8686-0a2de9fb5b47" src="https://github.com/user-attachments/assets/a77a562a-2e57-45a9-bdc8-5f853e761106" />

The system architecture can be described as follows:

* Users interact with the NapFi web interface to deposit assets.
* The **UnifiedVault.sol** contract holds user deposits and communicates with **StrategyRouter.sol**, which decides where to allocate funds.
* The Strategy Router connects to protocol adapters such as AaveAdapter or CurveAdapter.
* An off-chain AI service (built with Python and FastAPI) analyzes yield data and returns optimized allocation ratios.
* The frontend, built in React with Thirdweb SDK and Tailwind, displays real-time performance data to users.

Main components include:

* UnifiedVault.sol – manages deposits, withdrawals, and yield accounting.
* StrategyRouter.sol – routes funds between active strategies based on AI input.
* Adapters – protocol connectors that handle interactions with DeFi platforms.
* Creative Contracts – for future tokenized music or art vaults.

---

### Tech Stack

Smart contracts are written in Solidity and tested using Foundry.
Security relies on OpenZeppelin libraries and rigorous fuzz testing.
The AI backend uses Python and FastAPI.
Frontend development is based on React, Tailwind, Wagmi, and Thirdweb SDK.
The protocol is deployed on Optimism and supports Base and Polygon.
For data and file storage, NapFi uses IPFS and NFT.Storage.

---

### Folder Structure

* **core**: UnifiedVault.sol, StrategyRouter.sol, and protocol adapters.
* **creative**: MusicVaultFactory, RoyaltyDistributor, and ArtistProfileRegistry.
* **utils**: helper contracts such as SafeMath and AccessControl.
* **script**: deployment scripts for Foundry.
* **test**: Foundry test files for vault and strategy logic.

---

### Setup and Deployment

## 📁 Folder Structure

```bash
napfi-smartcontracts/
├── src/
│   ├── core/
│   │   ├── DeFi  
│   │   │   ├── UnifiedVault.sol                # Core vault logic for deposits & yield optimization
│   │   │   ├── VaultHelpers.sol
│   │   └── adapters/                    # I Havent made adapter but do ERC-4626 complienece from here? or BaseStrategy.sol? 
│   │       ├── AaveAdapter.sol
│   │       ├── CompoundAdapter.sol
│   │       └── CurveAdapter.sol
│   │   └── Registry.sol
│   └── interfaces/                      # Havent implemented any of this
│       ├── IERC4626.sol
│       ├── IERC7540.sol
│       └── IERC7575.sol
│       └── IFeeAccepted.sol
│       └── IHealthCheck.sol
│       └── IStrategyAPI.sol
│       └── IVaultAPI.sol
│   └── utils/                           # Still no idea what to do
│   └── Oracle/   
│       └── PriceOracle.sol              # Still not implementing any oracle
│       └── YieldOracle.sol
│   └── TokenTest/
│   └── security/
│   └── BaseStrategy.sol
│   └── CommonFeeOracle.sol
│   └── HealthCheckOverall.sol
├── script/
│   ├── DeployVault.s.sol                # Foundry deploy script for main vault
│   └── SetupStrategies.s.sol            # Setup script to initialize protocol adapters
├── test/
│   ├── VaultTest.t.sol
│   ├── StrategyRouterTest.t.sol
│   └── MusicVaultTest.t.sol
├── foundry.toml
└── README.md

```

🟢 Initial Commit: Core vault + adapters
🟣 v0.2 Commit: Added creative vault stack (MusicVaultFactory, RoyaltyDistributor)
🧠 v0.3 Commit: AI integration microservice (NapFi Brain)

⚙️ Setup & Deployment
1. Prerequisites
Make sure you have:

bash
Salin kode
# Node.js v18+
# Foundry (forge)
# Python 3.10+ for AI microservice
# MetaMask connected to Optimism RPC

2️. Installation
Clone the repository and install dependencies:

bash
Salin kode
git clone https://github.com/n6p-finance/n6p-smart-contract.git
cd napfi-smartcontracts
forge install

3️. Compile Contracts
```
forge build
```

4️. Run Tests
```
forge test -vvv
```

5️. Deploy to Optimism Testnet
Edit .env to include your keys:

```
OPTIMISM_RPC="https://optimism-sepolia.infura.io/v3/YOUR_API_KEY"
PRIVATE_KEY="YOUR_PRIVATE_KEY"
ETHERSCAN_API_KEY="YOUR_OPTIMISTIC_ETHERSCAN_KEY"
```

Then run:

```
forge script script/DeployVault.s.sol \
  --rpc-url $OPTIMISM_RPC \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

## AI Integration (NapFi Brain)
NapFi uses an off-chain AI engine to enhance decision-making by analyzing:

Historical APY and TVL trends

Risk metrics from DeFi protocols

Gas cost optimization

Volatility-adjusted yield predictions

Setup AI Engine
```
cd ai-engine
pip install -r requirements.txt
python app.py
```

### AI Integration

NapFi includes a backend AI engine built with FastAPI.
It provides three main functions:

1. Yield prediction
2. Risk scoring for DeFi protocols
3. Strategy optimization suggestions

Example API endpoints:

* `/api/apy` returns predicted yields
* `/api/strategy` provides allocation recommendations

To run the AI engine locally, navigate to the AI folder and start the server with `python app.py`.

---

### Creative Finance (Phase 2)

In its second phase, NapFi will expand into the creative finance space.
Users and artists will be able to:

* Tokenize creative projects such as songs or artworks
* Fund and stake into creative vaults
* Receive automated royalty payments
* Verify IP ownership through the Ethereum Attestation Service (EAS)

---

### Security

NapFi prioritizes safety and auditability:

* Uses OpenZeppelin’s security modules such as AccessControl and Ownable
* Performs fuzz and invariant testing using Foundry
* Includes timelock mechanisms for upgrade governance
* External audit planned before mainnet deployment

---

### Roadmap

Phase 0: Prototype vault contracts – completed
Phase 1: AI-integrated DeFi vault system – in development
Phase 2: Creative vault system for tokenized assets – in research
Phase 3: Full Layer 2 deployment with cross-chain vault support – planned

---

### Contributors

Founder and Lead Developer: Asyam Jayanegara
Smart Contract Developer: NapFi Labs
Backend and AI Development: NapFi AI Team
Frontend Design: NapFi Studio

---

### License

NapFi Smart Contracts are released under the MIT License (© 2025 NapFi Labs).
The codebase is open for use, modification, and distribution with attribution.

---

### Vision

NapFi aims to merge intelligent financial systems with the creative economy.
It is built to make DeFi smarter, more adaptive, and more human — where finance, AI, and art coexist within one decentralized ecosystem.

---
