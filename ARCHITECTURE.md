Absolutely! Here’s a **clean, README-friendly rewrite** of your NapFi AI System Architecture, fully integrating RWA/DeFi modularity and Lunar Bot. I structured it for clarity, Markdown readability, and ease of understanding for developers or contributors.

---

# NapFi AI System Architecture

## Overview

NapFi AI is a **hybrid RWA + DeFi yield aggregator** designed to optimize returns across both real-world tokenized assets (RWA) and on-chain DeFi protocols, separating concerns into **registry, vaults, strategies, AI decision modules, and automation**. This ensures flexibility, composability, and easier governance.

---

## Core Components

### 1. Registry

* **Description:** Central registry that maintains a list of all active vaults and their associated strategies. Handles governance and lookup functionality.
* **Responsibilities:**

  * Tracks all RWA and DeFi vaults.
  * Maps each vault to its approved strategies.
  * Tags vaults with `VaultType` (RWA or DeFi).
  * Provides lookup functions for aggregator vaults to discover active vaults and strategies.
  * Handles access control for adding/updating vaults and strategies.

### 2. Aggregator Vault

* **Description:** Top-level user-facing contract that accepts deposits and manages routing to underlying vaults. Provides a unified ERC-4626 interface.
* **Responsibilities:**

  * Accepts user deposits and issues shares.
  * Queries the registry to route funds to appropriate vaults:

    * **ERC-7540 RWA vaults** for real-world tokenized assets.
    * **ERC-4626 DeFi vaults** for liquid crypto yield assets.
  * Aggregates TVL and share accounting across all vaults.
  * Manages withdrawal requests by pulling funds from underlying vaults as needed.

### 3. RWA Vault(s)

* **Type:** ERC-7540
* **Description:** Handles real-world tokenized assets (e.g., bonds, invoices, tokenized stocks) with **async deposit/withdrawal flows**.
* **Responsibilities:**

  * Accept deposits from aggregator vault.
  * Track pending / claimable balances until RWA settles.
  * Integrate with RWA strategies to generate yield.
  * Report NAV (net asset value) to aggregator vault.

### 4. DeFi Vault(s)

* **Type:** ERC-4626
* **Description:** Handles liquid DeFi protocols such as Aave, Curve, or Compound. Supports **synchronous deposits/withdrawals**.
* **Responsibilities:**

  * Accept deposits from aggregator vault.
  * Route funds to one or more DeFi strategies for yield generation.
  * Report TVL and share price back to aggregator vault.

### 5. Strategies

* **RWA Strategy:**

  * Invests in tokenized real-world assets.
  * Handles async claim and settlement flows.
* **DeFi Strategy:**

  * Interacts with on-chain DeFi protocols to earn yield.
  * Supports synchronous harvests and returns funds to vault on request.
* **Notes:**

  * Strategies are modular and can be added or removed via the registry.
  * Each vault may support multiple strategies with different risk/yield profiles.

### 6. AI Decision Module

* **Description:** Optional module that can influence allocation decisions based on market conditions, yield optimization, or risk parameters.
* **Responsibilities:**

  * Provide signals for aggregator vault to rebalance allocations.
  * Suggest optimal vault or strategy distribution.

### 7. Lunar Bot (Keeper / Automation Agent)

* **Description:** Dedicated automation agent ensuring the system runs smoothly without manual intervention. Lunar Bot monitors vaults, strategies, and the aggregator vault to automate routine operations.
* **Key Responsibilities:**

  1. **Rebalancing Vaults**

     * Detects imbalance between RWA and DeFi vault allocations.
     * Executes fund redistribution automatically according to AI recommendations.
  2. **RWA Claim Settlements**

     * Monitors ERC-7540 vaults for pending claims or maturity events.
     * Triggers `claim()` or settlement functions to update balances.
  3. **DeFi Strategy Harvesting**

     * Calls `harvest()` on DeFi strategies to collect yield.
     * Updates vault share price and TVL after harvest.
  4. **Automated Withdrawal Support**

     * Pulls funds from strategies or vaults to fulfill aggregator withdrawals efficiently.
     * Reduces latency for async RWA vaults.
  5. **AI-Driven Allocation Execution**

     * Interfaces with AI Decision Module to adjust allocations automatically.
* **Integration:**

  * Operates outside user-facing contracts but with privileged permissions.
  * Works alongside AI module for optimal yield distribution.
  * Can be extended for health checks, performance monitoring, or emergency actions.
* **Benefits:**

  * Reduces manual intervention.
  * Ensures timely execution of strategy operations.
  * Maintains optimal allocation across hybrid vaults.

# NapFi AI Contracts & Interaction Table

| Component / Contract   | Type / ERC Standard | Description / Responsibility                                                                                  | Interacts With / Controlled By                                  |
| ---------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| **Registry**           | Internal / Custom   | Central registry for vaults and strategies. Maintains mapping, access control, and lookup for aggregator.     | Aggregator Vault, Lunar Bot                                     |
| **Aggregator Vault**   | ERC-4626            | User-facing vault; routes deposits to underlying RWA or DeFi vaults, issues shares, manages withdrawals.      | Users, Registry, RWA Vaults, DeFi Vaults, Lunar Bot             |
| **RWA Vault(s)**       | ERC-7540            | Handles tokenized real-world assets with async flows; reports NAV.                                            | Aggregator Vault, RWA Strategy, Lunar Bot                       |
| **DeFi Vault(s)**      | ERC-4626            | Handles on-chain DeFi protocols; supports synchronous deposits/withdrawals; reports TVL/share price.          | Aggregator Vault, DeFi Strategy, Lunar Bot                      |
| **RWA Strategy**       | Internal / Custom   | Implements real-world asset investment logic; async claim/settlement.                                         | RWA Vault, Lunar Bot                                            |
| **DeFi Strategy**      | Internal / Custom   | Implements DeFi yield-generating logic; synchronous harvests and returns funds to vaults.                     | DeFi Vault, Lunar Bot                                           |
| **AI Decision Module** | Internal / Custom   | Provides allocation signals for hybrid RWA + DeFi vaults.                                                     | Aggregator Vault, Lunar Bot                                     |
| **Lunar Bot**          | Automation Agent    | Keeper/automation agent: rebalances vaults, harvests strategies, settles RWA claims, executes AI allocations. | Registry, Aggregator Vault, RWA Vaults, DeFi Vaults, Strategies |

---

## System Flow

1. **User Deposit**

   * User approves aggregator vault to spend tokens.
   * Calls `deposit()` on aggregator vault → receives shares.

2. **Routing to Vaults**

   * Aggregator queries registry for active vaults by type.
   * Deposits routed:

     * ERC-7540 → RWA vaults
     * ERC-4626 → DeFi vaults

3. **Strategy Allocation**

   * Vaults allocate funds to approved strategies.
   * Yield generated according to strategy logic:

     * Async for RWA
     * Synchronous for DeFi

4. **Automated Operations (Lunar Bot)**

   * Rebalances vaults.
   * Executes RWA claims.
   * Harvests DeFi strategies.
   * Ensures vaults stay optimized per AI signals.

5. **Withdrawal**

   * User requests withdrawal.
   * Aggregator pulls funds from vaults.
   * Vaults may call strategies if needed.
   * Tokens returned, shares burned.

6. **NAV / Reporting**

   * Vaults report TVL/NAV to aggregator.
   * Aggregator aggregates data for UI and analytics.

---

## Architecture Diagram

```
                  ┌─────────────────────┐
                  │   Registry Contract │
                  │(vaults ↔ strategies)│
                  └─────────┬──────────┘
                            │
                  ┌─────────▼───────────┐
                  │   Aggregator Vault  │
                  │   (ERC-4626)        │
                  └─────────┬──────────┘
            ┌───────────────┴───────────────────────┐───────────────────> flashloan (Check UniswapV2/V3/V4Pair.sol (swap function))
            ▼                                       ▼
┌───────────────┐                         ┌───────────────┐
│ RWA Vault(s)  │                         │ DeFi Vault(s) │
│ ERC-7540      │                         │ ERC-4626      │
└─────┬─────────┘                         └─────┬─────────┘
      ▼                                         ▼
┌───────────────┐                         ┌───────────────┐
│ RWA Strategy  │                         │ DeFi Strategy │
└───────────────┘                         └───────────────┘
      ▲                                       ▲
      │                                       │
      └─────────────── Lunar Bot ────────────┘
          (automation / keeper operations)
```

---

## Key Principles

* **Single Registry:** Centralized source of truth for vaults and strategies; supports both RWA and DeFi.
* **Modularity:** Vaults, strategies, aggregator, and AI are separable and upgradeable.
* **Unified Interface:** Aggregator vault exposes ERC-4626 to users.
* **Async vs Sync Handling:** RWA vaults use ERC-7540; DeFi vaults use ERC-4626.
* **Extensibility:** New vaults, strategies, or AI modules can be added without disrupting the system.

---

## Future Improvements

* Dynamic AI-driven allocation between RWA and DeFi vaults.
* Multi-vault aggregation for finer allocation.
* Governance modules for vaults, strategies, and registry parameters.
* Enhanced automation: auto-harvest and RWA claim settlement.
* Gas optimizations for multi-vault operations.


