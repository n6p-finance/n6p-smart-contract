// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../core/DeFi/VaultDeFi.sol";
import "../strategy/OmniRestakeStrategy.sol";

/**
 * @title OmniRestakeStrategyForkTest
 * @notice Fork tests for OmniRestakeStrategy using Goerli/Holesky testnet
 * @dev Tests real protocol interactions on forked testnet
 */
contract OmniRestakeStrategyForkTest is Test {
    // Testnet addresses (Holesky/Goerli)
    address constant STETH_TESTNET = 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034; // Holesky stETH
    address constant EIGEN_STRATEGY_MANAGER_TESTNET = 0x858646372CC42E1A627fcE94aa7A7033e7CF075A;
    
    // LRT testnet addresses
    address constant KELP_RSETH_TESTNET = 0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7;
    address constant RENZO_EZETH_TESTNET = 0xbf5495Efe5DB9ce00f80364C8B423567e58d2110;
    
    // Test users
    address constant WHALE = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Test whale
    address constant USER1 = address(0x100);
    address constant USER2 = address(0x200);
    
    // Contracts
    Vault public vault;
    OmniRestakeStrategy public strategy;
    IERC20 public stETH;
    
    // Test parameters
    uint256 public constant TEST_DEPOSIT_AMOUNT = 10 ether;
    uint256 public constant INITIAL_WHALE_BALANCE = 1000 ether;
    
    // Fork setup
    uint256 public forkId;
    string public constant RPC_URL = "https://ethereum-holesky-rpc.publicnode.com";
    
    function setUp() public {
        // Create fork
        forkId = vm.createFork(RPC_URL);
        vm.selectFork(forkId);
        
        // Setup tokens
        stETH = IERC20(STETH_TESTNET);
        
        // Impersonate whale and get stETH
        vm.startPrank(WHALE);
        deal(address(stETH), WHALE, INITIAL_WHALE_BALANCE, true);
        vm.stopPrank();
        
        // Deploy vault
        address governance = address(this);
        address rewards = address(this);
        address management = address(this);
        address guardian = address(this);
        
        vault = new Vault();
        vault.initialize(
            address(stETH),
            governance,
            rewards,
            "OmniRestake Vault",
            "omniSTETH",
            guardian,
            management
        );
        
        // Deploy strategy
        strategy = new OmniRestakeStrategy(address(vault));
        
        // Add strategy to vault
        vault.addStrategy(
            address(strategy),
            9500, // 95% debt ratio
            1 ether, // min debt per harvest
            1000 ether, // max debt per harvest
            1000 // 10% performance fee
        );
        
        // Set deposit limit
        vault.setDepositLimit(10000 ether);
        
        console.log("Setup complete:");
        console.log("Vault:", address(vault));
        console.log("Strategy:", address(strategy));
        console.log("Initial Whale Balance:", stETH.balanceOf(WHALE));
    }
    
    function testForkSetup() public {
        // Verify fork is working
        assertTrue(stETH.balanceOf(WHALE) >= INITIAL_WHALE_BALANCE);
        assertEq(address(vault.token()), address(stETH));
        assertEq(strategy.vault(), address(vault));
        assertEq(strategy.want(), address(stETH));
    }
    
    function testUserDepositAndWithdraw() public {
        uint256 depositAmount = 5 ether;
        
        // User1 deposits
        vm.startPrank(USER1);
        deal(address(stETH), USER1, depositAmount, true);
        
        stETH.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, USER1);
        
        assertGt(shares, 0, "Should receive shares");
        assertEq(vault.balanceOf(USER1), shares, "User should have shares");
        assertEq(stETH.balanceOf(USER1), 0, "User stETH should be deposited");
        
        vm.stopPrank();
        
        // Check vault state
        uint256 vaultAssets = vault.totalAssets();
        assertGe(vaultAssets, depositAmount, "Vault should have assets");
        
        console.log("User deposit test:");
        console.log("Shares issued:", shares);
        console.log("Vault total assets:", vaultAssets);
    }
    
    function testStrategyInvestmentFlow() public {
        uint256 depositAmount = 10 ether;
        
        // Setup initial deposit
        vm.startPrank(WHALE);
        stETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, WHALE);
        vm.stopPrank();
        
        // Check initial state
        uint256 initialStrategyAssets = strategy.estimatedTotalAssets();
        console.log("Initial strategy assets:", initialStrategyAssets);
        
        // Harvest to deploy funds
        vm.roll(block.number + 100); // Advance blocks
        vm.warp(block.timestamp + 1 days); // Advance time
        
        uint256 debtPayment = strategy.harvest();
        console.log("Harvest debt payment:", debtPayment);
        
        // Check deployed allocations
        uint256 deployedBalance = strategy.balanceDeployed();
        uint256 wantBalance = strategy.balanceOfWant();
        
        console.log("After harvest:");
        console.log("Deployed balance:", deployedBalance);
        console.log("Want balance:", wantBalance);
        console.log("Total strategy assets:", strategy.estimatedTotalAssets());
        
        // Should have deployed most funds according to allocations
        assertGt(deployedBalance, 0, "Should have deployed funds");
        assertLt(wantBalance, depositAmount, "Should not keep all funds in want");
        
        // Test pending rewards estimation
        uint256 pendingRewards = strategy.pendingRewards();
        console.log("Pending rewards estimate:", pendingRewards);
    }
    
    function testMultipleHarvests() public {
        uint256 depositAmount = 20 ether;
        
        // Setup deposit
        vm.startPrank(WHALE);
        stETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, WHALE);
        vm.stopPrank();
        
        // Multiple harvest cycles
        for (uint256 i = 0; i < 3; i++) {
            console.log("\n--- Harvest Cycle %s ---", i + 1);
            
            uint256 beforeAssets = strategy.estimatedTotalAssets();
            
            // Advance time significantly to simulate rewards
            vm.roll(block.number + 1000);
            vm.warp(block.timestamp + 7 days);
            
            uint256 debtPayment = strategy.harvest();
            uint256 afterAssets = strategy.estimatedTotalAssets();
            
            console.log("Before harvest:", beforeAssets);
            console.log("After harvest:", afterAssets);
            console.log("Debt payment:", debtPayment);
            console.log("Gain:", strategy.totalGain());
            console.log("Loss:", strategy.totalLoss());
            
            // Strategy should maintain or grow assets
            assertGe(afterAssets, beforeAssets - 1 ether, "Assets should not decrease significantly");
        }
    }
    
    function testWithdrawFromStrategy() public {
        uint256 depositAmount = 15 ether;
        uint256 withdrawAmount = 5 ether;
        
        // Setup deposit and harvest
        vm.startPrank(WHALE);
        stETH.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, WHALE);
        vm.stopPrank();
        
        // Harvest to deploy funds
        vm.roll(block.number + 100);
        vm.warp(block.timestamp + 1 days);
        strategy.harvest();
        
        uint256 beforeWithdraw = strategy.estimatedTotalAssets();
        console.log("Assets before withdraw:", beforeWithdraw);
        
        // Withdraw from vault (will call strategy withdraw)
        vm.startPrank(WHALE);
        uint256 withdrawn = vault.withdraw(withdrawAmount, WHALE, 100); // 1% max loss
        
        console.log("Withdrawn amount:", withdrawn);
        console.log("Assets after withdraw:", strategy.estimatedTotalAssets());
        
        assertGe(withdrawn, withdrawAmount * 99 / 100, "Should withdraw at least 99% of requested");
        assertEq(stETH.balanceOf(WHALE), withdrawn, "Should receive stETH");
        
        vm.stopPrank();
    }
    
    function testEmergencyExit() public {
        uint256 depositAmount = 10 ether;
        
        // Setup deposit and harvest
        vm.startPrank(WHALE);
        stETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, WHALE);
        vm.stopPrank();
        
        // Harvest to deploy funds
        strategy.harvest();
        uint256 deployedBefore = strategy.balanceDeployed();
        assertGt(deployedBefore, 0, "Should have deployed funds");
        
        // Enable emergency exit
        strategy.setEmergencyExit();
        assertTrue(strategy.emergencyExit(), "Emergency exit should be enabled");
        
        // Harvest in emergency mode should liquidate all positions
        uint256 debtPayment = strategy.harvest();
        
        uint256 deployedAfter = strategy.balanceDeployed();
        uint256 wantAfter = strategy.balanceOfWant();
        
        console.log("Emergency exit results:");
        console.log("Deployed before:", deployedBefore);
        console.log("Deployed after:", deployedAfter);
        console.log("Want after:", wantAfter);
        console.log("Debt payment:", debtPayment);
        
        // Should have minimal deployed funds after emergency exit
        assertLt(deployedAfter, 1 ether, "Should have liquidated most positions");
        assertGt(wantAfter, 0, "Should have funds in want");
    }
    
    function testAllocationRebalancing() public {
        uint256 depositAmount = 10 ether;
        
        // Setup deposit
        vm.startPrank(WHALE);
        stETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, WHALE);
        vm.stopPrank();
        
        // Initial allocations
        (uint256 restake, uint256 lrt, uint256 pendle, uint256 morpho) = getAllocations();
        console.log("Initial allocations:");
        console.log("Restake:", restake);
        console.log("LRT:", lrt);
        console.log("Pendle:", pendle);
        console.log("Morpho:", morpho);
        
        // Change allocations
        uint256 newRestake = 6000;
        uint256 newLrt = 2000;
        uint256 newPendle = 1500;
        uint256 newMorpho = 500;
        
        strategy.setAllocations(newRestake, newLrt, newPendle, newMorpho);
        
        // Harvest to rebalance
        strategy.harvest();
        
        // Check new allocations are reflected
        (uint256 afterRestake, uint256 afterLrt, uint256 afterPendle, uint256 afterMorpho) = getAllocations();
        
        console.log("After rebalancing:");
        console.log("Restake:", afterRestake);
        console.log("LRT:", afterLrt);
        console.log("Pendle:", afterPendle);
        console.log("Morpho:", afterMorpho);
        
        assertEq(strategy.restakeAllocation(), newRestake, "Restake allocation should update");
        assertEq(strategy.lrtAllocation(), newLrt, "LRT allocation should update");
    }
    
    function testVaultStrategyIntegration() public {
        uint256 user1Deposit = 3 ether;
        uint256 user2Deposit = 7 ether;
        
        // User1 deposits
        vm.startPrank(USER1);
        deal(address(stETH), USER1, user1Deposit, true);
        stETH.approve(address(vault), user1Deposit);
        uint256 user1Shares = vault.deposit(user1Deposit, USER1);
        vm.stopPrank();
        
        // User2 deposits
        vm.startPrank(USER2);
        deal(address(stETH), USER2, user2Deposit, true);
        stETH.approve(address(vault), user2Deposit);
        uint256 user2Shares = vault.deposit(user2Deposit, USER2);
        vm.stopPrank();
        
        // Check vault state
        uint256 totalAssets = vault.totalAssets();
        uint256 totalSupply = vault.totalSupply();
        
        console.log("Multi-user deposit:");
        console.log("User1 shares:", user1Shares);
        console.log("User2 shares:", user2Shares);
        console.log("Total assets:", totalAssets);
        console.log("Total supply:", totalSupply);
        
        assertEq(totalAssets, user1Deposit + user2Deposit, "Total assets should match deposits");
        assertEq(totalSupply, user1Shares + user2Shares, "Total supply should match shares");
        
        // Harvest
        strategy.harvest();
        
        // Check price per share
        uint256 pricePerShare = vault.pricePerShare();
        console.log("Price per share:", pricePerShare);
        
        assertGe(pricePerShare, 1e18, "Price per share should be at least 1.0");
    }
    
    function testStrategyMetrics() public {
        uint256 depositAmount = 8 ether;
        
        // Setup
        vm.startPrank(WHALE);
        stETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, WHALE);
        vm.stopPrank();
        
        // Initial metrics
        console.log("Initial metrics:");
        console.log("Total debt:", strategy.totalDebt());
        console.log("Total gain:", strategy.totalGain());
        console.log("Total loss:", strategy.totalLoss());
        console.log("Last harvest:", strategy.lastHarvest());
        
        // Harvest and check metrics update
        vm.roll(block.number + 100);
        vm.warp(block.timestamp + 3 days);
        
        strategy.harvest();
        
        console.log("After harvest metrics:");
        console.log("Total debt:", strategy.totalDebt());
        console.log("Total gain:", strategy.totalGain());
        console.log("Total loss:", strategy.totalLoss());
        
        // Should have updated metrics
        assertGt(strategy.lastHarvest(), 0, "Last harvest should be updated");
    }
    
    // Helper function to get current allocation percentages
    function getAllocations() public view returns (uint256 restake, uint256 lrt, uint256 pendle, uint256 morpho) {
        restake = strategy.restakeAllocation();
        lrt = strategy.lrtAllocation();
        pendle = strategy.pendleAllocation();
        morpho = strategy.morphoAllocation();
    }
    
    // Helper to simulate time passage and harvest
    function simulateYield(uint256 daysToAdvance) public {
        vm.roll(block.number + daysToAdvance * 7200); // ~7200 blocks per day
        vm.warp(block.timestamp + daysToAdvance * 1 days);
        strategy.harvest();
    }
    
    // Test gas usage for critical functions
    function testGasUsage() public {
        uint256 depositAmount = 2 ether;
        
        vm.startPrank(WHALE);
        stETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, WHALE);
        vm.stopPrank();
        
        // Test harvest gas
        uint256 gasBefore = gasleft();
        strategy.harvest();
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Harvest gas used:", gasUsed);
        assertLt(gasUsed, 5_000_000, "Harvest should use reasonable gas");
    }
}