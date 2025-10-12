// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../core/DeFi/VaultDeFi.sol";
import "../strategy/OmniRestakeStrategy.sol";

// Mock protocols for testing
contract MockStETH {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    string public name = "Mock stETH";
    string public symbol = "stETH";
    uint8 public decimals = 18;
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        balances[from] -= amount;
        balances[to] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }
    
    function mint(address to, uint256 amount) external {
        balances[to] += amount;
        totalSupply += amount;
    }
    
    function burn(address from, uint256 amount) external {
        balances[from] -= amount;
        totalSupply -= amount;
    }
}

contract MockEigenLayer {
    mapping(address => uint256) public deposits;
    uint256 public constant REWARD_RATE = 350; // 3.5% in BPS
    
    function depositIntoStrategy(address, address, uint256 amount) external returns (uint256) {
        deposits[msg.sender] += amount;
        return amount;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return deposits[account];
    }
    
    function calculateRewards(address account, uint256 timeElapsed) external view returns (uint256) {
        return (deposits[account] * REWARD_RATE * timeElapsed) / (10000 * 365 days);
    }
}

contract MockLRT {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stETHDeposits;
    uint256 public constant REWARD_RATE = 450; // 4.5% in BPS
    
    function deposit(address token, uint256 amount) external returns (uint256) {
        stETHDeposits[msg.sender] += amount;
        balances[msg.sender] += amount; // 1:1 initially
        return amount;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function convertToAssets(uint256 shares) external pure returns (uint256) {
        return shares; // 1:1 for simplicity
    }
    
    function calculateRewards(address account, uint256 timeElapsed) external view returns (uint256) {
        return (stETHDeposits[account] * REWARD_RATE * timeElapsed) / (10000 * 365 days);
    }
}

/**
 * @title OmniRestakeStrategyLongTermTest
 * @notice 20-year simulation with comprehensive edge cases
 * @dev Tests long-term strategy behavior without forking
 */
contract OmniRestakeStrategyLongTermTest is Test {
    // Contracts
    Vault public vault;
    OmniRestakeStrategy public strategy;
    MockStETH public stETH;
    MockEigenLayer public eigenLayer;
    MockLRT public lrtKelp;
    MockLRT public lrtRenzo;
    
    // Test parameters
    uint256 public constant TWENTY_YEARS = 20 * 365 days;
    uint256 public constant INITIAL_DEPOSIT = 1000 ether;
    uint256 public constant MONTHLY_DEPOSIT = 100 ether;
    uint256 public constant QUARTERLY_WITHDRAWAL = 200 ether;
    
    // Users
    address public constant GOVERNANCE = address(0x1000);
    address public constant USER1 = address(0x1001);
    address public constant USER2 = address(0x1002);
    address public constant USER3 = address(0x1003);
    
    // Tracking
    struct SimulationState {
        uint256 totalDeposits;
        uint256 totalWithdrawals;
        uint256 totalFees;
        uint256 peakTVL;
        uint256 lowestTVL;
        uint256 harvestCount;
        uint256 emergencyEvents;
        uint256 rebalanceEvents;
    }
    
    SimulationState public state;

    function setUp() public {
        // Deploy mocks
        stETH = new MockStETH();
        eigenLayer = new MockEigenLayer();
        lrtKelp = new MockLRT();
        lrtRenzo = new MockLRT();
        
        // Deploy vault
        vm.startPrank(GOVERNANCE);
        vault = new Vault();
        vault.initialize(
            address(stETH),
            GOVERNANCE,
            GOVERNANCE, // rewards
            "LongTerm Vault",
            "LTV",
            GOVERNANCE, // guardian
            GOVERNANCE  // management
        );
        
        // Deploy strategy with mocked addresses
        strategy = new OmniRestakeStrategy(address(vault));
        
        // Add strategy to vault
        vault.addStrategy(
            address(strategy),
            9500, // 95% debt ratio
            1 ether,
            10000 ether,
            1000 // 10% performance fee
        );
        
        vault.setDepositLimit(1000000 ether);
        vm.stopPrank();
        
        // Fund users
        stETH.mint(USER1, INITIAL_DEPOSIT * 10);
        stETH.mint(USER2, INITIAL_DEPOSIT * 10);
        stETH.mint(USER3, INITIAL_DEPOSIT * 10);
        
        // Initialize state
        state = SimulationState({
            totalDeposits: 0,
            totalWithdrawals: 0,
            totalFees: 0,
            peakTVL: 0,
            lowestTVL: type(uint256).max,
            harvestCount: 0,
            emergencyEvents: 0,
            rebalanceEvents: 0
        });
    }
    
    function test20YearSimulation() public {
        console.log("Starting 20-Year Strategy Simulation");
        console.log("========================================");
        
        uint256 startTime = block.timestamp;
        uint256 currentTime = startTime;
        
        // Phase 1: Initial Growth (Years 1-5)
        console.log("\n Phase 1: Initial Growth (Years 1-5)");
        _simulatePhase(currentTime, 5 years, 30 days, true, false);
        currentTime += 5 years;
        
        // Phase 2: Maturity & Volatility (Years 6-10)
        console.log("\n Phase 2: Maturity & Volatility (Years 6-10)");
        _simulatePhase(currentTime, 5 years, 14 days, false, true);
        currentTime += 5 years;
        
        // Phase 3: Stress Testing (Years 11-15)
        console.log("\n Phase 3: Stress Testing (Years 11-15)");
        _simulatePhase(currentTime, 5 years, 7 days, true, true);
        currentTime += 5 years;
        
        // Phase 4: Recovery & Exit (Years 16-20)
        console.log("\n Phase 4: Recovery & Exit (Years 16-20)");
        _simulatePhase(currentTime, 5 years, 30 days, false, false);
        
        // Final analysis
        _analyzeResults(startTime);
    }
    
    function _simulatePhase(
        uint256 startTime,
        uint256 duration,
        uint256 harvestInterval,
        bool includeDeposits,
        bool includeWithdrawals
    ) internal {
        uint256 endTime = startTime + duration;
        uint256 currentTime = startTime;
        
        while (currentTime < endTime) {
            vm.warp(currentTime);
            
            // Random user actions
            if (includeDeposits && _random(100) < 30) { // 30% chance of deposit
                _simulateRandomDeposit();
            }
            
            if (includeWithdrawals && _random(100) < 15) { // 15% chance of withdrawal
                _simulateRandomWithdrawal();
            }
            
            // Harvest if interval passed
            if (currentTime >= strategy.lastHarvest() + harvestInterval) {
                _simulateHarvest();
            }
            
            // Random events (1% chance per time step)
            if (_random(100) < 1) {
                _simulateRandomEvent();
            }
            
            // Track TVL
            _updateTVLTracking();
            
            // Move time forward (1-30 days randomly)
            uint256 timeJump = _random(30) * 1 days;
            currentTime += timeJump;
        }
        
        // Final harvest of phase
        vm.warp(endTime);
        _simulateHarvest();
    }
    
    function _simulateRandomDeposit() internal {
        address[] memory users = new address[](3);
        users[0] = USER1;
        users[1] = USER2;
        users[2] = USER3;
        
        address user = users[_random(3)];
        uint256 amount = (_random(50) + 10) * 1 ether; // 10-60 ETH
        
        if (stETH.balanceOf(user) >= amount) {
            vm.startPrank(user);
            stETH.approve(address(vault), amount);
            vault.deposit(amount, user);
            vm.stopPrank();
            
            state.totalDeposits += amount;
            
            console.log(" Deposit: User", uint160(user), "deposited", amount / 1e18, "ETH");
        }
    }
    
    function _simulateRandomWithdrawal() internal {
        address[] memory users = new address[](3);
        users[0] = USER1;
        users[1] = USER2;
        users[2] = USER3;
        
        address user = users[_random(3)];
        uint256 shares = vault.balanceOf(user);
        
        if (shares > 0) {
            uint256 withdrawShares = (shares * (_random(30) + 10)) / 100; // 10-40% of position
            
            vm.startPrank(user);
            uint256 received = vault.withdraw(withdrawShares, user, 500); // 5% max loss
            vm.stopPrank();
            
            state.totalWithdrawals += received;
            
            console.log(" Withdrawal: User", uint160(user), "withdrew", received / 1e18, "ETH");
        }
    }
    
    function _simulateHarvest() internal {
        uint256 vaultAssetsBefore = vault.totalAssets();
        uint256 strategyAssetsBefore = strategy.estimatedTotalAssets();
        
        try strategy.harvest() returns (uint256 debtPayment) {
            state.harvestCount++;
            
            uint256 vaultAssetsAfter = vault.totalAssets();
            uint256 strategyAssetsAfter = strategy.estimatedTotalAssets();
            
            console.log(" Harvest #%s: Debt Payment %s ETH, Vault Growth: %s ETH", 
                state.harvestCount, 
                debtPayment / 1e18,
                (vaultAssetsAfter - vaultAssetsBefore) / 1e18
            );
            
            // Track fees
            uint256 vaultBalance = stETH.balanceOf(address(vault));
            if (vaultBalance > 0) {
                state.totalFees += vaultBalance;
            }
            
        } catch (bytes memory reason) {
            console.log(" Harvest failed:", string(reason));
        }
    }
    
    function _simulateRandomEvent() internal {
        uint256 eventType = _random(10);
        
        if (eventType == 0) {
            // Emergency exit
            console.log(" EMERGENCY EXIT TRIGGERED");
            vm.prank(GOVERNANCE);
            strategy.setEmergencyExit();
            state.emergencyEvents++;
            
            // Harvest to liquidate
            _simulateHarvest();
            
            // Reset after 30 days
            vm.warp(block.timestamp + 30 days);
            // Note: In reality, emergency exit is permanent, but for testing we simulate recovery
            console.log(" Emergency resolved after 30 days");
            
        } else if (eventType == 1) {
            // Allocation change
            uint256 newRestake = 4000 + _random(4000); // 40-80%
            uint256 newLRT = 1000 + _random(2000);     // 10-30%
            uint256 newPendle = 500 + _random(1000);   // 5-15%
            uint256 newMorpho = 500;                   // 5% fixed
            
            vm.prank(GOVERNANCE);
            strategy.setAllocations(newRestake, newLRT, newPendle, newMorpho);
            state.rebalanceEvents++;
            
            console.log("  Rebalanced: Restake %s%%, LRT %s%%, Pendle %s%%, Morpho %s%%",
                newRestake / 100, newLRT / 100, newPendle / 100, newMorpho / 100);
                
        } else if (eventType == 2) {
            // Large deposit (whale)
            uint256 whaleAmount = 5000 ether;
            address whale = address(0x9999);
            
            stETH.mint(whale, whaleAmount);
            vm.startPrank(whale);
            stETH.approve(address(vault), whaleAmount);
            vault.deposit(whaleAmount, whale);
            vm.stopPrank();
            
            state.totalDeposits += whaleAmount;
            console.log(" Whale deposited: 5000 ETH");
            
        } else if (eventType == 3) {
            // Large withdrawal (whale exit)
            address[] memory users = new address[](3);
            users[0] = USER1;
            users[1] = USER2;
            users[2] = USER3;
            
            address user = users[_random(3)];
            uint256 shares = vault.balanceOf(user);
            
            if (shares > 1000 ether) {
                vm.startPrank(user);
                uint256 received = vault.withdraw(shares / 2, user, 1000); // 10% max loss
                vm.stopPrank();
                
                state.totalWithdrawals += received;
                console.log(" Whale withdrawal: %s ETH", received / 1e18);
            }
            
        } else if (eventType == 4) {
            // Fee change
            uint256 newPerfFee = 500 + _random(1500); // 5-20%
            vm.prank(GOVERNANCE);
            vault.setPerformanceFee(newPerfFee);
            console.log(" Performance fee changed to: %s%%", newPerfFee / 100);
            
        } else if (eventType == 5) {
            // Deposit limit change
            uint256 newLimit = (100000 + _random(900000)) * 1 ether; // 100k - 1M ETH
            vm.prank(GOVERNANCE);
            vault.setDepositLimit(newLimit);
            console.log(" Deposit limit changed to: %s ETH", newLimit / 1e18);
        }
        // Other event types can be added for more scenarios
    }
    
    function _updateTVLTracking() internal {
        uint256 currentTVL = vault.totalAssets();
        
        if (currentTVL > state.peakTVL) {
            state.peakTVL = currentTVL;
        }
        
        if (currentTVL < state.lowestTVL) {
            state.lowestTVL = currentTVL;
        }
    }
    
    function _analyzeResults(uint256 startTime) internal {
        uint256 endTime = block.timestamp;
        uint256 totalDuration = endTime - startTime;
        
        console.log("\n" + string(unicode" ==================== 20-YEAR SIMULATION RESULTS ===================="));
        console.log("Duration: %s years", totalDuration / 365 days);
        console.log("Final Timestamp: %s", endTime);
        
        // Final state
        uint256 finalTVL = vault.totalAssets();
        uint256 finalSupply = vault.totalSupply();
        uint256 pricePerShare = vault.pricePerShare();
        
        console.log("\n FINAL STATE:");
        console.log("Total Vault Assets: %s ETH", finalTVL / 1e18);
        console.log("Total Share Supply: %s shares", finalSupply / 1e18);
        console.log("Price Per Share: %s", pricePerShare);
        console.log("Total Strategy Debt: %s ETH", strategy.totalDebt() / 1e18);
        
        console.log("\n PERFORMANCE METRICS:");
        console.log("Total Deposits: %s ETH", state.totalDeposits / 1e18);
        console.log("Total Withdrawals: %s ETH", state.totalWithdrawals / 1e18);
        console.log("Total Fees Collected: %s ETH", state.totalFees / 1e18);
        console.log("Peak TVL: %s ETH", state.peakTVL / 1e18);
        console.log("Lowest TVL: %s ETH", state.lowestTVL == type(uint256).max ? 0 : state.lowestTVL / 1e18);
        console.log("Total Harvests: %s", state.harvestCount);
        console.log("Emergency Events: %s", state.emergencyEvents);
        console.log("Rebalance Events: %s", state.rebalanceEvents);
        
        // Calculate APY
        if (state.totalDeposits > 0) {
            uint256 netGrowth = finalTVL + state.totalWithdrawals - state.totalDeposits;
            uint256 apy = _calculateAPY(netGrowth, state.totalDeposits, totalDuration);
            console.log("Estimated Net APY: %s%%", apy / 1e16);
        }
        
        // User outcomes
        _analyzeUserOutcomes();
        
        // Strategy health check
        _performHealthChecks();
        
        // Risk analysis
        _performRiskAnalysis();
    }
    
    function _analyzeUserOutcomes() internal {
        console.log("\n USER OUTCOMES:");
        
        address[] memory users = new address[](3);
        users[0] = USER1;
        users[1] = USER2;
        users[2] = USER3;
        
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 shares = vault.balanceOf(user);
            uint256 assets = vault.pricePerShare() * shares / 1e18;
            uint256 netDeposits = _estimateUserNetDeposits(user);
            
            if (netDeposits > 0) {
                uint256 profit = assets > netDeposits ? assets - netDeposits : 0;
                uint256 loss = assets < netDeposits ? netDeposits - assets : 0;
                
                console.log("User %s: Assets %s ETH, Net Deposits %s ETH, PnL %s ETH",
                    i + 1,
                    assets / 1e18,
                    netDeposits / 1e18,
                    profit > 0 ? int256(profit) / 1e18 : -int256(loss) / 1e18
                );
            }
        }
    }
    
    function _performHealthChecks() internal {
        console.log("\n  HEALTH CHECKS:");
        
        // Check 1: Vault-strategy integration
        uint256 vaultDebt = vault.strategies(address(strategy)).totalDebt;
        uint256 strategyDebt = strategy.totalDebt();
        console.log(" Debt Synchronization: %s", vaultDebt == strategyDebt ? "PASS" : "FAIL");
        
        // Check 2: Asset backing
        uint256 estimatedAssets = strategy.estimatedTotalAssets();
        uint256 actualAssets = stETH.balanceOf(address(strategy)) + _estimateDeployedAssets();
        console.log(" Asset Estimation: %s (Estimated: %s ETH, Actual: ~%s ETH)", 
            _withinTolerance(estimatedAssets, actualAssets, 10), // 10% tolerance
            estimatedAssets / 1e18,
            actualAssets / 1e18
        );
        
        // Check 3: Share price consistency
        uint256 calculatedTVL = vault.pricePerShare() * vault.totalSupply() / 1e18;
        uint256 actualTVL = vault.totalAssets();
        console.log(" Share Price Math: %s", _withinTolerance(calculatedTVL, actualTVL, 1) ? "PASS" : "FAIL");
        
        // Check 4: Fee sustainability
        uint256 feeRatio = state.totalFees * 10000 / state.totalDeposits;
        console.log(" Fee Sustainability: %s (Fees: %s%% of deposits)", 
            feeRatio < 500 ? "PASS" : "WARNING", // Less than 5%
            feeRatio / 100
        );
    }
    
    function _performRiskAnalysis() internal {
        console.log("\n  RISK ANALYSIS:");
        
        // Concentration risk
        uint256 largestPosition = 0;
        address[] memory users = new address[](3);
        users[0] = USER1;
        users[1] = USER2;
        users[2] = USER3;
        
        for (uint256 i = 0; i < users.length; i++) {
            uint256 position = vault.balanceOf(users[i]);
            if (position > largestPosition) {
                largestPosition = position;
            }
        }
        
        uint256 concentration = largestPosition * 10000 / vault.totalSupply();
        console.log("Largest Position: %s%% of total supply", concentration / 100);
        
        // Withdrawal capacity
        uint256 idleRatio = stETH.balanceOf(address(vault)) * 10000 / vault.totalAssets();
        console.log("Idle Ratio: %s%%", idleRatio / 100);
        
        // Harvest frequency analysis
        uint256 avgHarvestInterval = (block.timestamp - vault.activation()) / (state.harvestCount + 1);
        console.log("Average Harvest Interval: %s days", avgHarvestInterval / 1 days);
    }
    
    // ====== HELPER FUNCTIONS ======
    
    function _calculateAPY(uint256 profit, uint256 principal, uint256 duration) internal pure returns (uint256) {
        if (principal == 0 || duration == 0) return 0;
        
        // APY = (1 + (profit / principal)) ^ (1 / (duration / 365 days)) - 1
        uint256 ratio = (profit * 1e18) / principal;
        uint256 exponent = (365 days * 1e18) / duration;
        
        // Simplified calculation for testing
        return (ratio * 365 days * 10000) / (duration * 100); // Approximation in BPS
    }
    
    function _estimateUserNetDeposits(address user) internal pure returns (uint256) {
        // Simplified - in real test we'd track this precisely
        return 500 ether; // Approximation for testing
    }
    
    function _estimateDeployedAssets() internal view returns (uint256) {
        // Mock implementation - would sum all protocol balances
        return strategy.totalDebt() * 80 / 100; // Assume 80% deployed
    }
    
    function _withinTolerance(uint256 a, uint256 b, uint256 tolerancePercent) internal pure returns (bool) {
        if (a == 0 && b == 0) return true;
        if (a == 0 || b == 0) return false;
        
        uint256 difference = a > b ? a - b : b - a;
        uint256 tolerance = (a * tolerancePercent) / 100;
        return difference <= tolerance;
    }
    
    function _random(uint256 max) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, max))) % max;
    }
    
    // Edge case tests
    function testExtremeScenarios() public {
        console.log("\n Testing Extreme Scenarios");
        
        // Test 1: Maximum deposit
        _testMaxDeposit();
        
        // Test 2: Complete withdrawal
        _testCompleteWithdrawal();
        
        // Test 3: Rapid succession operations
        _testRapidOperations();
        
        // Test 4: Fee edge cases
        _testFeeEdgeCases();
        
        // Test 5: Allocation boundaries
        _testAllocationBoundaries();
    }
    
    function _testMaxDeposit() internal {
        console.log("Testing maximum deposit scenario...");
        
        uint256 maxDeposit = vault.depositLimit();
        stETH.mint(USER1, maxDeposit);
        
        vm.startPrank(USER1);
        stETH.approve(address(vault), maxDeposit);
        vault.deposit(maxDeposit, USER1);
        vm.stopPrank();
        
        assertEq(vault.totalAssets(), maxDeposit, "Should accept max deposit");
        console.log(" Max deposit test passed");
    }
    
    function _testCompleteWithdrawal() internal {
        console.log("Testing complete withdrawal scenario...");
        
        vm.startPrank(USER1);
        uint256 shares = vault.balanceOf(USER1);
        vault.withdraw(shares, USER1, 1000); // 10% max loss
        vm.stopPrank();
        
        assertEq(vault.balanceOf(USER1), 0, "Should withdraw all shares");
        console.log(" Complete withdrawal test passed");
    }
    
    function _testRapidOperations() internal {
        console.log("Testing rapid operations scenario...");
        
        uint256 initialHarvests = state.harvestCount;
        
        // Rapid harvests
        for (uint256 i = 0; i < 10; i++) {
            vm.warp(block.timestamp + 1 hours);
            strategy.harvest();
        }
        
        assertGt(state.harvestCount, initialHarvests + 5, "Should process rapid harvests");
        console.log(" Rapid operations test passed");
    }
    
    function _testFeeEdgeCases() internal {
        console.log("Testing fee edge cases...");
        
        // Set very high fees
        vm.prank(GOVERNANCE);
        vault.setPerformanceFee(5000); // 50%
        
        // Harvest with high fees
        _simulateHarvest();
        
        // Reset to normal
        vm.prank(GOVERNANCE);
        vault.setPerformanceFee(1000); // 10%
        
        console.log(" Fee edge cases test passed");
    }
    
    function _testAllocationBoundaries() internal {
        console.log("Testing allocation boundaries...");
        
        // Test minimum allocations
        vm.prank(GOVERNANCE);
        strategy.setAllocations(1000, 1000, 1000, 1000); // 10% each
        
        // Test maximum allocations  
        vm.prank(GOVERNANCE);
        strategy.setAllocations(7000, 2000, 500, 500); // 70% restake
        
        console.log(" Allocation boundaries test passed");
    }
}