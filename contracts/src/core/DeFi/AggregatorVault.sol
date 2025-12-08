// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    AggregatorVaultAutoRebalance
    ---------------------------------------
    ✔ ERC4626-like aggregator
    ✔ Multi-strategy vault (idle + strategies)
    ✔ Automatic PUSH allocation
    ✔ NEW: Automatic PULL rebalancing
    ✔ NEW: Public rebalance() function
    ✔ Fully dynamic target ratios

    This version finally behaves like:
        - Yearn v2 Vault
        - Beefy Strategies w/ allocators
        - Enzyme yield allocator
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/* ----------------------------- ERC4626 Minimal ----------------------------- */
interface IERC4626Minimal {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

/* --------------------------- Strategy Interface ---------------------------- */
// Replace this and Use Aave v2 Strategy interface as base
interface IStrategy {
    function want() external view returns (address);
    function vault() external view returns (address);
    function withdraw(uint256 amount) external returns (uint256 actual);
    function estimatedTotalAssets() external view returns (uint256);
    function isActive() external view returns (bool);
}

/* ------------------------------- Ownable ---------------------------------- */
abstract contract SimpleOwnable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        require(initialOwner != address(0), "owner zero");
        owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }
    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "owner zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/* ============================= MAIN VAULT ============================= */
contract AggregatorVault is ERC20, IERC4626Minimal, SimpleOwnable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_BPS = 10_000; // 100%
    uint256 public constant YEAR_SECONDS = 31_556_952; // 365.2425 days

    IERC20 public immutable underlying;
    uint8 private immutable _assetDecimals;

    struct Strategy {
        address addr; // strategy contract
        uint256 debtRatioBps; // target ratio in BPS
        uint256 totalDebt; // current allocated debt
        bool active; // is strategy active
    }

    Strategy[] public strategies; // list of strategies
    mapping(address => uint256) public strategyIndex; // 1-based index // 0 = not found
    address[] public withdrawalQueue; // order of strategies for withdrawals

    uint256 public totalIdle; // idle funds in vault
    uint256 public totalDebt; // total allocated to strategies

    address public feeRecipient; // fees receiver
    uint256 public managementFeeBpsPerYear; // management fee in BPS per yearS
    uint256 public performanceFeeBps; // performance fee in BPS
    uint256 public lastAccruedTimestamp; // last management fee timestamp

    bool public emergencyShutdown; // emergency shutdown flag

    event StrategyAdded(address indexed strat, uint256 debtRatioBps); // strategy added
    event StrategyRemoved(address indexed strat); 
    event WithdrawalQueueSet(address[] queue); // withdrawal queue set for strategies that will be pulled from first
    event Reported(address indexed strat, uint256 gain, uint256 loss, uint256 payback);

    event StrategyPull(address indexed strat, uint256 amount);   /// rebalance for pull
    event StrategyPush(address indexed strat, uint256 amount);   /// rebalance for push
    event FullyRebalanced(uint256 idleBefore, uint256 idleAfter); /// rebalance complete in order to maintain ratios


    constructor(
        IERC20 _asset,
        string memory name_,
        string memory symbol_,
        address initialOwner_
    ) ERC20(name_, symbol_) SimpleOwnable(initialOwner_) {
        require(address(_asset) != address(0), "asset zero");
        underlying = _asset; 
        _assetDecimals = ERC20(address(_asset)).decimals();
        feeRecipient = initialOwner_;
        managementFeeBpsPerYear = 200;
        performanceFeeBps = 1000;
        lastAccruedTimestamp = block.timestamp;
    }

    /* ----------------------------- ERC4626 view ------------------------------ */

    function asset() external view override returns (address) { return address(underlying); }
    function decimals() public view override returns (uint8) { return _assetDecimals; }

    function totalAssets() public view override returns (uint256 sum) {
        sum = totalIdle;
        uint256 len = strategies.length;
        for (uint256 i; i < len; ) {
            Strategy storage s = strategies[i];
            if (s.active) {
                try IStrategy(s.addr).estimatedTotalAssets() returns (uint256 v) {
                    sum += v;
                } catch {}
            }
            unchecked { ++i; }
        }
    }

    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint256 ta = totalAssets();
        uint256 s = totalSupply();
        if (s == 0 || ta == 0) return assets;
        return (assets * s) / ta;
    }

    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 s = totalSupply();
        if (s == 0) return 0;
        uint256 ta = totalAssets();
        return (shares * ta) / s;
    }

    /* ------------------------- Deposit / Mint ------------------------- */
    // Rebalance called after deposit/mint to allocate new idle funds
    function deposit(uint256 assets, address recv) external override returns (uint256 shares) {
        require(!emergencyShutdown, "shutdown");
        underlying.safeTransferFrom(msg.sender, address(this), assets); // pull underlying
        totalIdle += assets;

        shares = totalSupply() == 0 ? assets : convertToShares(assets);
        _mint(recv, shares);
        emit Deposit(msg.sender, recv, assets, shares);

        _rebalanceCore(); /// NEW: rebalance after deposit
    }

    function mint(uint256 shares, address recv) external override returns (uint256 assets) {
        require(!emergencyShutdown, "shutdown");

        assets = convertToAssets(shares);
        underlying.safeTransferFrom(msg.sender, address(this), assets);
        totalIdle += assets;
        _mint(recv, shares);
        emit Deposit(msg.sender, recv, assets, shares);

        _rebalanceCore(); /// NEW
    }

    /* --------------------------- Withdraw / Redeem ---------------------------- */

    function _withdrawFromQueue(uint256 need) internal returns (uint256) {
        if (need == 0) return 0;

        uint256 len = withdrawalQueue.length;
        uint256 pulled;

        for (uint256 i; i < len && need > 0; ) {
            address strat = withdrawalQueue[i]; // strategy to withdraw from in order
            uint256 idx = strategyIndex[strat]; // 1-based index based on above mapping

            if (idx != 0) {
                Strategy storage s = strategies[idx - 1]; // get strategy structs metadata
                if (s.active && s.totalDebt != 0) { // only withdraw from active strategies with debt
                    uint256 req = s.totalDebt > need ? need : s.totalDebt;
                    uint256 actual;

                    (bool ok, bytes memory data) = strat.call(
                        abi.encodeWithSelector(IStrategy.withdraw.selector, req)
                    );

                    if (ok && data.length >= 32) {
                        assembly { actual := mload(add(data, 32)) }
                    }
                    if (actual > 0) {
                        if (actual > s.totalDebt) actual = s.totalDebt;
                        s.totalDebt -= actual;
                        totalDebt -= actual;
                        totalIdle += actual;
                        need -= actual;
                        pulled += actual;
                    }
                }
            }
            unchecked { ++i; }
        }
        return pulled;
    }


    function withdraw(uint256 assets, address recv, address owner_)
        external override returns (uint256 shares)
    {
        shares = convertToShares(assets);

        if (owner_ != msg.sender) {
            uint256 allowed = allowance(owner_, msg.sender);
            require(allowed >= shares, "allowance");
            _approve(owner_, msg.sender, allowed - shares);
        }
 
        if (assets > totalIdle) _withdrawFromQueue(assets - totalIdle); // try to pull from strategies
        require(assets <= totalIdle, "insufficient"); // final checks

        _burn(owner_, shares);
        totalIdle -= assets;
        underlying.safeTransfer(recv, assets);
        emit Withdraw(msg.sender, recv, owner_, assets, shares);
    }

    function redeem(uint256 shares, address recv, address owner_)
        external override returns (uint256 assets)
    {
        if (owner_ != msg.sender) {
            uint256 allowed = allowance(owner_, msg.sender);
            require(allowed >= shares, "allowance");
            _approve(owner_, msg.sender, allowed - shares);
        }

        assets = convertToAssets(shares);
        if (assets > totalIdle) _withdrawFromQueue(assets - totalIdle);
        require(assets <= totalIdle, "insufficient");

        _burn(owner_, shares);
        totalIdle -= assets;
        underlying.safeTransfer(recv, assets);
        emit Withdraw(msg.sender, recv, owner_, assets, shares);
    }

    /* ----------------------- Strategy Management ------------------------ */

    function addStrategy(address strat, uint256 ratioBps) external onlyOwner {
        require(ratioBps <= MAX_BPS, "too high");
        require(IStrategy(strat).want() == address(underlying), "wrong asset");

        uint256 sum = ratioBps;
        for (uint256 i; i < strategies.length; ) {
            sum += strategies[i].debtRatioBps;
            unchecked { ++i; }
        }
        require(sum <= MAX_BPS, "ratios exceed");

        strategies.push(Strategy(strat, ratioBps, 0, true));
        strategyIndex[strat] = strategies.length;
        withdrawalQueue.push(strat);
        emit StrategyAdded(strat, ratioBps);

        _rebalanceCore();
    }


    /* -------------------------- REPORT (harvest) -------------------------- */

    function report(uint256 gain, uint256 loss, uint256 payback) external {
        uint256 idx = strategyIndex[msg.sender];
        require(idx != 0, "not strat");

        Strategy storage s = strategies[idx - 1];
        require(s.active, "inactive");

        if (loss > 0) {
            uint256 d = loss >= s.totalDebt ? s.totalDebt : loss;
            s.totalDebt -= d;
            totalDebt -= d;
        }

        if (payback > 0) {
            uint256 d = payback >= s.totalDebt ? s.totalDebt : payback;
            s.totalDebt -= d;
            totalDebt -= d;
            totalIdle += payback;
        }

        if (gain > 0) totalIdle += gain;

        emit Reported(msg.sender, gain, loss, payback);

        _rebalanceCore();  /// NEW: rebalance on report
    }


    /* =====================================================================
                          AUTO-REBALANCE ENGINE (NEW)
       ===================================================================== */

    /// @notice Public function anyone can call (keeper, user, UI)
    function rebalance() external { _rebalanceCore(); }

    function _rebalanceCore() internal {
        uint256 idleBefore = totalIdle;

        _pullOverweight();   /// NEW: withdraw from overweight strategies
        _pushUnderweight();  /// existing allocateIdle() simplified

        emit FullyRebalanced(idleBefore, totalIdle);
    }


    /// STEP 1: PULL excess from overweight strategies
    function _pullOverweight() internal {
        uint256 ta = totalAssets();
        if (ta == 0) return;

        uint256 len = strategies.length;

        for (uint256 i; i < len; ) {
            Strategy storage s = strategies[i]; // get strategy structs metadata
            if (!s.active || s.debtRatioBps == 0) { // skip inactive or zero-ratio %
                unchecked { ++i; }
                continue;
            }

// compute target debt based on current totalAssets
// totalAssets = 100,000 USDC
// strategy has debtRatioBps = 3000 (30%)
// Then:
// target = 100,000 * 3000 / 10,000 = 30,000

            uint256 target = (ta * s.debtRatioBps) / MAX_BPS; // target debt for strategy

            if (s.totalDebt > target) {
                uint256 excess = s.totalDebt - target;
                uint256 actual;

// withdraw from strategy
// Meaning:
//  - If call succeeded AND strategy returned a 32-byte value
//  - Load it from memory
// This ensures compatibility with strategies that:
//  - return nothing
//  - return wrong size
//  - revert
//  - do not exist (call ok = false)

                (bool ok, bytes memory data) = s.addr.call(
                    abi.encodeWithSelector(IStrategy.withdraw.selector, excess) // withdraw excess
                );
                if (ok && data.length >= 32) {
                    assembly { actual := mload(add(data, 32)) } // get returned actual withdrawn
                }
                if (actual > 0) {
                    if (actual > s.totalDebt) actual = s.totalDebt;

                    s.totalDebt -= actual; // update strategy debt
                    totalDebt -= actual; // update vault total debt
                    totalIdle += actual; // increase vault idle funds

                    emit StrategyPull(s.addr, actual); // emit event
                }
            }

            unchecked { ++i; }
        }
    }


    /// STEP 2: PUSH into underweight strategies using idle funds
    function _pushUnderweight() internal {
        uint256 ta = totalAssets();
        if (ta == 0 || totalIdle == 0) return;

        uint256 len = strategies.length;

        for (uint256 i; i < len && totalIdle > 0; ) {
            Strategy storage s = strategies[i];
            if (s.active && s.debtRatioBps > 0) {
                uint256 target = (ta * s.debtRatioBps) / MAX_BPS;

                if (s.totalDebt < target) {
                    uint256 need = target - s.totalDebt;
                    uint256 amount = need > totalIdle ? totalIdle : need;

                    if (amount > 0) {
                        underlying.safeTransfer(s.addr, amount);
                        s.totalDebt += amount;
                        totalDebt += amount;
                        totalIdle -= amount;

                        emit StrategyPush(s.addr, amount);
                    }
                }
            }
            unchecked { ++i; }
        }
    }


    /* --------------------------- Fees (unchanged) --------------------------- */

    function _accrueManagementFee() internal {
        uint256 nowTs = block.timestamp;
        uint256 elapsed = nowTs - lastAccruedTimestamp;
        if (elapsed == 0) return;

        uint256 ta = totalAssets();
        uint256 feeAssets =
            (ta * managementFeeBpsPerYear * elapsed) / (MAX_BPS * YEAR_SECONDS);

        if (feeAssets > 0) {
            uint256 sharesForFee = convertToShares(feeAssets);
            if (sharesForFee > 0) _mint(feeRecipient, sharesForFee);
        }
        lastAccruedTimestamp = nowTs;
    }


    /* ----------------------------- Admin tools ------------------------------ */

    function setFeeRecipient(address r) external onlyOwner { feeRecipient = r; }
    function setManagementFee(uint256 bps) external onlyOwner { managementFeeBpsPerYear = bps; }
    function setPerformanceFee(uint256 bps) external onlyOwner { performanceFeeBps = bps; }

    function setEmergencyShutdown(bool flag) external onlyOwner {
        emergencyShutdown = flag;
    }
}
