// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/DeFi/VaultDeFi.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title RestakeAggregatorStrategy
 * @notice Multi-layer yield strategy combining:
 *  - Base Layer: stETH restaking on EigenLayer (~3-4% APY)
 *  - Boost Layer: LRT/AVS rewards from EigenLayer points and AVS payments (+3-6% APY)
 *  - Rehypothecation Layer: Morpho Blue/Pendle yield swaps (+2-5% APY)
 * @dev Expected Net APY: 9-14% with high Sharpe ratio
 */
contract RestakeAggregatorStrategy {
    using SafeERC20 for IERC20;
    using Math for uint256;
    
    // ====== CORE VAULT INTEGRATION ======
    Vault public immutable vault;
    IERC20 public immutable want; // stETH
    
    // ====== STRATEGY PARAMETERS ======
    uint256 public constant MAX_BPS = 10_000;
    uint256 public debtRatio = 9500; // 95% active, 5% idle buffer
    
    // Allocation targets (in BPS)
    uint256 public restakeAllocation = 5000; // 50% to EigenLayer
    uint256 public lrtAllocation = 3000;     // 30% to LRT boost
    uint256 public pendleAllocation = 1500;  // 15% to Pendle yield
    uint256 public morphoAllocation = 500;   // 5% to Morpho Blue
    
    // Performance tracking
    uint256 public totalDebt;
    uint256 public totalGain;
    uint256 public totalLoss;
    uint256 public lastHarvest;
    
    // Emergency controls
    bool public emergencyExit = false;
    
    // ====== PROTOCOL ADDRESSES ======
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant EIGEN_STRATEGY_MANAGER = 0x858646372CC42E1A627fcE94aa7A7033e7CF075A;
    address public constant EIGEN_DELEGATION_MANAGER = 0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A;
    
    // LRT protocols (example addresses)
    address public constant KELP_RSETH = 0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7;
    address public constant RENZO_EZETH = 0xbf5495Efe5DB9ce00f80364C8B423567e58d2110;
    
    // Yield protocols
    address public constant MORPHO_BLUE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address public constant PENDLE_ROUTER = 0x0000000001E4ef00d069e71d6bA041b0A16F7eA0;
    
    // ====== STATE TRACKING ======
    struct Position {
        uint256 amount;
        uint256 timestamp;
    }
    
    mapping(address => Position) public eigenPositions;
    mapping(address => uint256) public lrtBalances;
    mapping(address => uint256) public pendlePositions;
    mapping(address => uint256) public morphoPositions;
    
    uint256 public pendingEigenRewards;
    uint256 public pendingLRTRewards;
    uint256 public pendingPendleRewards;
    
    // ====== EVENTS ======
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
    event AllocationsUpdated(uint256 restake, uint256 lrt, uint256 pendle, uint256 morpho);
    event EmergencyExitEnabled();
    event StrategyReported(uint256 gain, uint256 loss, uint256 debtPaid, uint256 lockedProfit);
    
    constructor(address _vault) {
        require(_vault != address(0), "Invalid vault");
        vault = Vault(_vault);
        want = IERC20(vault.token());
        
        // Verify we're using stETH
        require(address(want) == STETH, "Strategy only for stETH");
        
        _setupApprovals();
    }
    
    function _setupApprovals() internal {
        // NOTE: COnsidering using 'safeApprove' method before launch
        // Approve EigenLayer
        IERC20(STETH).approve(EIGEN_STRATEGY_MANAGER, type(uint256).max);
        
        // Approve LRT protocols
        IERC20(STETH).approve(KELP_RSETH, type(uint256).max);
        IERC20(STETH).approve(RENZO_EZETH, type(uint256).max);
        
        // Approve yield protocols
        IERC20(STETH).approve(PENDLE_ROUTER, type(uint256).max);
        IERC20(STETH).approve(MORPHO_BLUE, type(uint256).max);
    }
    
    // ====== VAULT INTEGRATION ======
    modifier onlyVault() {
        require(msg.sender == address(vault), "!vault");
        _;
    }
    
    modifier onlyGovernance() {
        require(msg.sender == vault.governance(), "!governance");
        _;
    }
    
    modifier onlyAuthorized() {
        require(
            msg.sender == address(vault) || 
            msg.sender == vault.governance() || 
            msg.sender == vault.management(),
            "!authorized"
        );
        _;
    }
    
    function name() external pure returns (string memory) {
        return "RestakeAggregatorStrategy";
    }
    
    function estimatedTotalAssets() external view returns (uint256) {
        return balanceOfWant() + balanceDeployed() + pendingRewards();
    }
    
    // ====== ASSET TRACKING ======
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }
    
    function balanceDeployed() public view returns (uint256) {
        return balanceInEigenLayer() + balanceInLRT() + balanceInPendle() + balanceInMorpho();
    }
    
    function balanceInEigenLayer() public view returns (uint256) {
        // Sum all EigenLayer positions
        uint256 total;
        // This would integrate with EigenLayer's delegation manager
        // Placeholder implementation
        return total;
    }
    
    function balanceInLRT() public view returns (uint256) {
        // Convert LRT balances back to stETH value
        uint256 total;
        
        // Kelp rsETH balance to stETH
        if (IERC20(KELP_RSETH).balanceOf(address(this)) > 0) {
            // This would use Kelp's conversion rate
            total += IERC20(KELP_RSETH).balanceOf(address(this));
        }
        
        // Renzo ezETH balance to stETH
        if (IERC20(RENZO_EZETH).balanceOf(address(this)) > 0) {
            // This would use Renzo's conversion rate
            total += IERC20(RENZO_EZETH).balanceOf(address(this));
        }
        
        return total;
    }
    
    function balanceInPendle() public view returns (uint256) {
        // Return Pendle LP positions value in stETH
        // Implementation depends on specific Pendle markets
        uint256 total;
        // Placeholder - would calculate based on LP positions and exchange rates
        return total;
    }
    
    function balanceInMorpho() public view returns (uint256) {
        // Return supplied collateral in Morpho Blue markets
        uint256 total;
        // Placeholder - would iterate through active Morpho positions
        return total;
    }
    
    function pendingRewards() public view returns (uint256) {
        uint256 rewards;
        
        // EigenLayer points and AVS rewards (estimated)
        rewards += calculateEigenRewards();
        
        // LRT platform rewards
        rewards += calculateLRTRewards();
        
        // Pendle yield rewards
        rewards += calculatePendleRewards();
        
        // Morpho interest
        rewards += calculateMorphoInterest();
        
        return rewards;
    }
    
    function calculateEigenRewards() internal view returns (uint256) {
        // Calculate estimated EigenLayer rewards (points + AVS payments)
        // This is complex and would require integration with EigenLayer's reward system
        uint256 estimatedAPY = 350; // 3.5% in BPS
        uint256 eigenBalance = balanceInEigenLayer();
        
        if (eigenBalance == 0) return 0;
        
        // Simple time-based estimation
        uint256 timeElapsed = block.timestamp - lastHarvest;
        if (timeElapsed == 0) return 0;
        
        return (eigenBalance * estimatedAPY * timeElapsed) / (MAX_BPS * 365 days);
    }
    
    function calculateLRTRewards() internal view returns (uint256) {
        // Calculate LRT platform rewards
        uint256 estimatedAPY = 450; // 4.5% in BPS
        uint256 lrtBalance = balanceInLRT();
        
        if (lrtBalance == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - lastHarvest;
        if (timeElapsed == 0) return 0;
        
        return (lrtBalance * estimatedAPY * timeElapsed) / (MAX_BPS * 365 days);
    }
    
    function calculatePendleRewards() internal view returns (uint256) {
        // Calculate Pendle yield trading rewards
        uint256 estimatedAPY = 350; // 3.5% in BPS
        uint256 pendleBalance = balanceInPendle();
        
        if (pendleBalance == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - lastHarvest;
        if (timeElapsed == 0) return 0;
        
        return (pendleBalance * estimatedAPY * timeElapsed) / (MAX_BPS * 365 days);
    }
    
    function calculateMorphoInterest() internal view returns (uint256) {
        // Calculate Morpho Blue lending interest
        uint256 estimatedAPY = 200; // 2% in BPS
        uint256 morphoBalance = balanceInMorpho();
        
        if (morphoBalance == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - lastHarvest;
        if (timeElapsed == 0) return 0;
        
        return (morphoBalance * estimatedAPY * timeElapsed) / (MAX_BPS * 365 days);
    }
    
    // ====== CORE STRATEGY LOGIC ======
    function harvest() external onlyVault returns (uint256) {
        if (emergencyExit) {
            return _liquidateAllPositions();
        }
        
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtPayment = 0;
        
        // 1. Harvest rewards from all protocols
        uint256 harvestedRewards = _harvestAllRewards();
        
        // 2. Calculate performance
        uint256 totalAssetsBefore = totalDebt;
        uint256 totalAssetsAfter = balanceDeployed() + balanceOfWant() + harvestedRewards;
        
        if (totalAssetsAfter > totalAssetsBefore) {
            profit = totalAssetsAfter - totalAssetsBefore;
            totalGain += profit;
        } else {
            loss = totalAssetsBefore - totalAssetsAfter;
            totalLoss += loss;
        }
        
        // 3. Rebalance according to allocation targets
        _rebalancePortfolio();
        
        // 4. Report to vault
        debtPayment = _reportToVault(profit, loss);
        
        lastHarvest = block.timestamp;
        emit Harvested(profit, loss, debtPayment, vault.debtOutstanding(address(this)));
        
        return debtPayment;
    }
    
    function _harvestAllRewards() internal returns (uint256) {
        uint256 totalHarvested = 0;
        
        // Harvest EigenLayer rewards (when available)
        // Placeholder - EigenLayer reward claiming mechanism TBD
        
        // Harvest LRT rewards
        totalHarvested += _harvestLRTRewards();
        
        // Harvest Pendle rewards
        totalHarvested += _harvestPendleRewards();
        
        // Harvest Morpho interest
        totalHarvested += _harvestMorphoInterest();
        
        return totalHarvested;
    }
    
    function _harvestLRTRewards() internal returns (uint256) {
        uint256 harvested = 0;
        
        // Kelp DAO reward claiming (when available)
        // try ILRT(KELP_RSETH).claimRewards() returns (uint256 rewards) {
        //     harvested += rewards;
        // } catch {}
        
        // Renzo reward claiming (when available)
        // try ILRT(RENZO_EZETH).claimRewards() returns (uint256 rewards) {
        //     harvested += rewards;
        // } catch {}
        
        return harvested;
    }
    
    function _harvestPendleRewards() internal returns (uint256) {
        // Pendle reward claiming logic
        // This would involve claiming Pendle tokens and swapping to stETH
        return 0; // Placeholder
    }
    
    function _harvestMorphoInterest() internal returns (uint256) {
        // Morpho Blue interest accrual is automatic
        // This would involve withdrawing accrued interest
        return 0; // Placeholder
    }
    
    function _rebalancePortfolio() internal {
        uint256 totalAssets = balanceDeployed() + balanceOfWant();
        if (totalAssets == 0) return;
        
        // Calculate target allocations
        uint256 targetEigen = (totalAssets * restakeAllocation) / MAX_BPS;
        uint256 targetLRT = (totalAssets * lrtAllocation) / MAX_BPS;
        uint256 targetPendle = (totalAssets * pendleAllocation) / MAX_BPS;
        uint256 targetMorpho = (totalAssets * morphoAllocation) / MAX_BPS;
        
        uint256 currentEigen = balanceInEigenLayer();
        uint256 currentLRT = balanceInLRT();
        uint256 currentPendle = balanceInPendle();
        uint256 currentMorpho = balanceInMorpho();
        
        // Rebalance EigenLayer position
        if (currentEigen < targetEigen) {
            uint256 toDeposit = targetEigen - currentEigen;
            _depositToEigenLayer(toDeposit);
        } else if (currentEigen > targetEigen) {
            uint256 toWithdraw = currentEigen - targetEigen;
            _withdrawFromEigenLayer(toWithdraw);
        }
        
        // Rebalance LRT positions
        if (currentLRT < targetLRT) {
            uint256 toDeposit = targetLRT - currentLRT;
            _depositToLRT(toDeposit);
        } else if (currentLRT > targetLRT) {
            uint256 toWithdraw = currentLRT - targetLRT;
            _withdrawFromLRT(toWithdraw);
        }
        
        // Rebalance Pendle positions
        if (currentPendle < targetPendle) {
            uint256 toDeposit = targetPendle - currentPendle;
            _depositToPendle(toDeposit);
        } else if (currentPendle > targetPendle) {
            uint256 toWithdraw = currentPendle - targetPendle;
            _withdrawFromPendle(toWithdraw);
        }
        
        // Rebalance Morpho positions
        if (currentMorpho < targetMorpho) {
            uint256 toDeposit = targetMorpho - currentMorpho;
            _depositToMorpho(toDeposit);
        } else if (currentMorpho > targetMorpho) {
            uint256 toWithdraw = currentMorpho - targetMorpho;
            _withdrawFromMorpho(toWithdraw);
        }
    }
    
    // ====== PROTOCOL INTEGRATIONS ======
    function _depositToEigenLayer(uint256 amount) internal {
        if (amount == 0) return;
        
        // Deposit to EigenLayer strategy
        // This will vary based on specific EigenLayer strategy implementation
        // IEigenLayer(EIGEN_STRATEGY_MANAGER).depositIntoStrategy(
        //     eigenStrategyAddress,
        //     STETH,
        //     amount
        // );
        
        // Track position
        eigenPositions[EIGEN_STRATEGY_MANAGER].amount += amount;
        eigenPositions[EIGEN_STRATEGY_MANAGER].timestamp = block.timestamp;
    }
    
    function _withdrawFromEigenLayer(uint256 amount) internal {
        if (amount == 0) return;
        
        // Withdraw from EigenLayer (may involve queueing)
        // IEigenLayer(EIGEN_STRATEGY_MANAGER).queueWithdrawal(...);
        
        // Update position tracking
        eigenPositions[EIGEN_STRATEGY_MANAGER].amount -= amount;
    }
    
    function _depositToLRT(uint256 amount) internal {
        if (amount == 0) return;
        
        // Distribute between different LRT protocols for diversification
        uint256 kelpAmount = amount / 2;
        uint256 renzoAmount = amount - kelpAmount;
        
        if (kelpAmount > 0) {
            // Deposit to Kelp DAO
            // ILRT(KELP_RSETH).deposit(STETH, kelpAmount);
            lrtBalances[KELP_RSETH] += kelpAmount;
        }
        
        if (renzoAmount > 0) {
            // Deposit to Renzo
            // ILRT(RENZO_EZETH).deposit(STETH, renzoAmount);
            lrtBalances[RENZO_EZETH] += renzoAmount;
        }
    }
    
    function _withdrawFromLRT(uint256 amount) internal {
        if (amount == 0) return;
        
        // Withdraw proportionally from LRT positions
        uint256 totalLRT = balanceInLRT();
        if (totalLRT == 0) return;
        
        uint256 kelpShare = (lrtBalances[KELP_RSETH] * amount) / totalLRT;
        uint256 renzoShare = amount - kelpShare;
        
        if (kelpShare > 0) {
            // ILRT(KELP_RSETH).withdraw(kelpShare);
            lrtBalances[KELP_RSETH] -= kelpShare;
        }
        
        if (renzoShare > 0) {
            // ILRT(RENZO_EZETH).withdraw(renzoShare);
            lrtBalances[RENZO_EZETH] -= renzoShare;
        }
    }
    
    function _depositToPendle(uint256 amount) internal {
        if (amount == 0) return;
        
        // Implement Pendle yield strategy
        // This would involve swapping stETH for Pendle LP tokens
        // or participating in specific yield markets
        // Placeholder implementation
    }
    
    function _withdrawFromPendle(uint256 amount) internal {
        if (amount == 0) return;
        
        // Withdraw from Pendle positions
        // Placeholder implementation
    }
    
    function _depositToMorpho(uint256 amount) internal {
        if (amount == 0) return;
        
        // Supply collateral to Morpho Blue markets
        // This would target high-yield, low-risk markets
        // Placeholder implementation
    }
    
    function _withdrawFromMorpho(uint256 amount) internal {
        if (amount == 0) return;
        
        // Withdraw from Morpho Blue positions
        // Placeholder implementation
    }
    
    // ====== VAULT REPORTING ======
    function _reportToVault(uint256 profit, uint256 loss) internal returns (uint256) {
        // Report performance to vault and receive new debt allocation
        uint256 debtPayment = vault.report(profit, loss, 0);
        
        // Update total debt based on vault's response
        totalDebt = vault.strategies(address(this)).totalDebt;
        
        emit StrategyReported(profit, loss, 0, vault.lockedProfit());
        return debtPayment;
    }
    
    // ====== WITHDRAWAL LOGIC ======
    function withdraw(uint256 _amount) external onlyVault returns (uint256) {
        uint256 amount = _amount;
        uint256 balance = balanceOfWant();
        
        if (balance < amount) {
            uint256 shortfall = amount - balance;
            
            // Withdraw from protocols in order of liquidity
            if (shortfall > 0) shortfall -= _withdrawFromMorpho(shortfall);
            if (shortfall > 0) shortfall -= _withdrawFromPendle(shortfall);
            if (shortfall > 0) shortfall -= _withdrawFromLRT(shortfall);
            if (shortfall > 0) shortfall -= _withdrawFromEigenLayer(shortfall);
            
            // Update balance after withdrawals
            balance = balanceOfWant();
            amount = Math.min(amount, balance);
        }
        
        if (amount > 0) {
            want.safeTransfer(address(vault), amount);
        }
        
        return amount;
    }
    
    function _liquidateAllPositions() internal returns (uint256) {
        // Emergency exit - liquidate all positions
        _withdrawFromMorpho(type(uint256).max);
        _withdrawFromPendle(type(uint256).max);
        _withdrawFromLRT(type(uint256).max);
        _withdrawFromEigenLayer(type(uint256).max);
        
        uint256 totalBalance = balanceOfWant();
        if (totalBalance > 0) {
            want.safeTransfer(address(vault), totalBalance);
        }
        
        return totalBalance;
    }
    
    // ====== ADMIN FUNCTIONS ======
    function setAllocations(
        uint256 _restakeAllocation,
        uint256 _lrtAllocation, 
        uint256 _pendleAllocation,
        uint256 _morphoAllocation
    ) external onlyAuthorized {
        require(
            _restakeAllocation + _lrtAllocation + _pendleAllocation + _morphoAllocation <= MAX_BPS,
            "Allocations exceed 100%"
        );
        
        restakeAllocation = _restakeAllocation;
        lrtAllocation = _lrtAllocation;
        pendleAllocation = _pendleAllocation;
        morphoAllocation = _morphoAllocation;
        
        emit AllocationsUpdated(_restakeAllocation, _lrtAllocation, _pendleAllocation, _morphoAllocation);
    }
    
    function setEmergencyExit() external onlyAuthorized {
        emergencyExit = true;
        emit EmergencyExitEnabled();
    }
    
    function migrate(address newStrategy) external onlyVault {
        require(newStrategy != address(0), "Invalid strategy");
        
        // Withdraw all funds to vault for migration
        _liquidateAllPositions();
        
        // Vault will handle the actual migration
    }
    
    // ====== FALLBACKS ======
    receive() external payable {}
    
    // Emergency function to recover ERC20 tokens sent by mistake
    function sweep(address token) external onlyGovernance {
        require(token != address(want), "Cannot sweep want token");
        require(token != STETH, "Cannot sweep stETH");
        
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(vault.governance(), amount);
    }
}