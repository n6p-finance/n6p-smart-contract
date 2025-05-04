# NapFi AI System Architecture

## Overview

NapFi AI is a DeFi yield optimizer that uses a modular architecture to manage user funds and optimize returns. The system consists of several key components that work together to provide a secure and efficient yield farming experience.

## Core Components

### 1. TestToken (ERC20)
- **Address**: `0x47112e1874336Dae68Bd14D0c4373902db63aB6F`
- **Description**: A simple ERC20 token used for testing the system. In a production environment, this would be replaced with real assets like USDC, ETH, etc.
- **Key Functions**:
  - `mint(address to, uint256 amount)`: Creates new tokens and assigns them to the specified address.
  - Standard ERC20 functions: `transfer`, `transferFrom`, `approve`, etc.

### 2. TestVault
- **Address**: `0x616102e0C0af01aF67a877031a199d880178913D`
- **Description**: The entry point for users to deposit and withdraw funds. The vault issues shares to users in proportion to their deposits and manages the connection to the controller.
- **Key Functions**:
  - `deposit(uint256 _amount)`: Accepts tokens from users and issues shares in return.
  - `withdraw(uint256 _shares)`: Burns shares and returns the corresponding tokens to users.
  - `setController(address _controller)`: Sets the controller address for the vault.
  - `getVaultBalance()`: Returns the total token balance of the vault.
  - `getPricePerShare()`: Calculates the current value of each share.

### 3. TestController
- **Address**: `0x92FcbFaa42AD84d0EF230AA5e38eaEa4af129fc9`
- **Description**: Manages the allocation of funds between different strategies. The controller acts as an intermediary between the vault and the strategies.
- **Key Functions**:
  - `addStrategy(address _strategy)`: Adds a new strategy to the controller (can only be called by the vault).
  - `depositFromVault(uint256 _amount)`: Accepts tokens from the vault.
  - `allocateToStrategy(address _strategy, uint256 _amount)`: Sends tokens to a specific strategy.
  - `returnFundsToVault(uint256 _amount)`: Returns tokens to the vault.
  - `getControllerBalance()`: Returns the total token balance of the controller.
  - `getStrategyCount()`: Returns the number of strategies managed by the controller.
  - `getStrategyInfo(uint256 _index)`: Returns information about a specific strategy.

### 4. TestStrategy
- **Address**: `0x377ea45291DED69A76a9959d32745af618Cc1C26`
- **Description**: Implements a specific yield-generating strategy. Each strategy has its own logic for generating returns on the deposited assets.
- **Key Functions**:
  - `generateYield()`: Simulates yield generation for testing purposes.
  - `withdraw(uint256 _amount)`: Returns tokens to the controller (can only be called by the controller).
  - `getStrategyBalance()`: Returns the total token balance of the strategy.
  - `apy()`: Returns the annual percentage yield of the strategy.

### 5. AIDecisionModule
- **Address**: `0x93F7d6566Aa4011aA7A0043Ddda4c6cCc3954BF7`
- **Description**: Makes decisions about how to allocate funds across different strategies based on market conditions and risk parameters.
- **Key Functions**: (Not fully implemented in the current version)

## System Flow

1. **User Deposit**:
   - User approves the vault to spend their tokens.
   - User calls `deposit()` on the vault, sending tokens and receiving shares in return.

2. **Fund Allocation**:
   - Vault approves the controller to spend tokens.
   - Vault calls `depositFromVault()` on the controller.
   - Controller calls `allocateToStrategy()` to distribute funds to strategies.

3. **Yield Generation**:
   - Strategies generate yield through various DeFi protocols and mechanisms.
   - In the test environment, this is simulated with the `generateYield()` function.

4. **Fund Withdrawal**:
   - When a user wants to withdraw, they call `withdraw()` on the vault with the number of shares they want to redeem.
   - If necessary, the vault requests funds from the controller by calling `returnFundsToVault()`.
   - The controller may need to call `withdraw()` on one or more strategies to gather the required funds.
   - The vault transfers tokens back to the user and burns their shares.

## Integration Testing

The system has been tested with a series of integration tests that verify the correct interaction between components:

1. **TestVaultControllerIntegration.t.sol**: Tests the integration between the vault, controller, and strategy.
2. **TestIntegratedSystem.s.sol**: A script that tests the basic flow of depositing, generating yield, and withdrawing.
3. **TestCompleteFlow.s.sol**: A more comprehensive script that tests the complete flow from deposit to yield generation to withdrawal.

## Frontend Integration

The frontend application interacts with the smart contracts through a set of ABIs and configuration settings:

- **CONTRACT_ADDRESSES**: Defined in `web3.tsx`, contains the addresses of all deployed contracts.
- **Component Integration**: The `ControllerInteraction.tsx` component provides a user interface for interacting with the controller and strategy.

## Future Improvements

1. **Access Control**: Implement proper access control mechanisms to secure the interactions between contracts.
2. **Multiple Strategies**: Support for multiple concurrent strategies with different risk profiles.
3. **Automated Rebalancing**: Implement automatic rebalancing of funds between strategies based on performance.
4. **Enhanced AI Decision Making**: Expand the AI decision module to make more sophisticated allocation decisions.
5. **Gas Optimization**: Optimize the contracts for gas efficiency in production environments.

## Deployment Information

All contracts are currently deployed on the Sepolia testnet. The deployment scripts can be found in the `contracts/script` directory:

- **DeployTestToken.s.sol**: Deploys the TestToken contract.
- **DeployTestVault.s.sol**: Deploys the TestVault contract.
- **DeployTestControllerAndStrategy.s.sol**: Deploys the TestController and TestStrategy contracts.
- **ConnectVaultToController.s.sol**: Sets up the connection between the vault and controller.

## Conclusion

The NapFi AI system provides a modular and extensible architecture for DeFi yield optimization. By separating concerns into distinct components (vault, controller, strategies), the system can be easily maintained and upgraded over time. The current implementation serves as a proof of concept and foundation for future development.
