// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* ---------- Minimal Strategy Interface ---------- */
interface IStrategy {
    function want() external view returns (address);
    function withdraw(uint256 amount) external returns (uint256);
    function estimatedTotalAssets() external view returns (uint256);
    function isActive() external view returns (bool);
}

/* ------------------------------------------------ */
contract AggregatorVaultProSimplified is
    ERC20,
    ReentrancyGuard,
    Ownable,
    Pausable
{
    using SafeERC20 for IERC20;

    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant SECONDS_PER_YEAR = 31_556_952;

    IERC20 public immutable underlying;
    uint8 private immutable assetDecimals;

    /* ---------- Strategy Struct ---------- */
    struct Strategy {
        address addr;
        uint256 debtRatioBps; // allocation %
        uint256 totalDebt;     // capital allocated
        bool active;
    }
    
    struct StrategyView {
        address addr;
        bool active;
        uint256 debtRatioBps;
        uint256 totalDebt;
        uint256 estimatedAssets;
    }

    Strategy[] public strategies;
    mapping(address => uint256) public indexOf; // index+1
    address[] public withdrawalQueue;

    /* ---------- Vault Balances ---------- */
    uint256 public totalIdle;
    uint256 public totalDebt;

    /* ---------- Fees ---------- */
    address public feeRecipient;
    uint256 public managementFeeBps;
    uint256 public performanceFeeBps;
    uint256 public lastFeeTimestamp;

    /* ---------- Limits ---------- */
    uint256 public depositLimit = type(uint256).max;
    bool public emergencyShutdown;

    /* ---------- Events ---------- */
    event Deposit(address caller, address owner, uint256 assets, uint256 shares);
    event Withdraw(address caller, address receiver, uint256 assets, uint256 shares);
    event StrategyAdded(address strat, uint256 ratio);
    event StrategyRemoved(address strat);
    event StrategyPush(address strat, uint256 amount);
    event StrategyPull(address strat, uint256 amount);
    event Rebalanced();

    /* ---------------------------------------------------------- */
    constructor(
        IERC20 _underlying,
        string memory _name,
        string memory _symbol,
        address _owner
    ) ERC20(_name, _symbol) Ownable(_owner) {
        underlying = _underlying;
        assetDecimals = ERC20(address(_underlying)).decimals();
        feeRecipient = _owner;

        managementFeeBps = 200; // 2%
        performanceFeeBps = 1000; // 10%
        lastFeeTimestamp = block.timestamp;
    }

    /* ============================================================
                        VIEW FUNCTIONS
       ============================================================ */

    function decimals() public view override returns (uint8) {
        return assetDecimals;
    }

    function asset() external view returns (address) {
        return address(underlying);
    }

    function strategiesLength() external view returns (uint256) {
        return strategies.length;
    }

    function totalAssets() public view returns (uint256 sum) {
        sum = totalIdle;
        uint256 len = strategies.length;

        for (uint256 i; i < len; ++i) {
            Strategy storage s = strategies[i];
            if (!s.active) continue;
            try IStrategy(s.addr).estimatedTotalAssets() returns (uint256 est) {
                sum += est;
            } catch {}
        }
    }

    function getStrategy(uint256 idx)
        external
        view
        returns (address addr, uint256 ratio, uint256 debt, bool active)
    {
        Strategy storage s = strategies[idx];
        return (s.addr, s.debtRatioBps, s.totalDebt, s.active);
    }

    /* ============================================================
                        ERC4626-LIKE LOGIC
       ============================================================ */

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 ts = totalSupply();
        uint256 ta = totalAssets();
        if (ts == 0 || ta == 0) return assets;
        return (assets * ts) / ta;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 ts = totalSupply();
        if (ts == 0) return 0;
        return (shares * totalAssets()) / ts;
    }

    /* --------------------------- Deposit --------------------------- */
    function deposit(uint256 assets, address receiver)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        require(assets > 0, "zero");
        require(totalAssets() + assets <= depositLimit, "limit");

        underlying.safeTransferFrom(msg.sender, address(this), assets);
        totalIdle += assets;

        shares = convertToShares(assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
        _rebalance();
    }

    /* --------------------------- Withdraw --------------------------- */
    function withdraw(uint256 assets, address receiver, address owner_)
        external
        nonReentrant
        returns (uint256 shares)
    {
        require(assets > 0, "zero");
        shares = convertToShares(assets);

        if (msg.sender != owner_) {
            uint256 allowed = allowance(owner_, msg.sender);
            require(allowed >= shares, "allow");
            _approve(owner_, msg.sender, allowed - shares);
        }

        if (assets > totalIdle) {
            uint256 need = assets - totalIdle;
            _withdrawFromQueue(need);
        }

        require(assets <= totalIdle, "lack");

        _burn(owner_, shares);
        totalIdle -= assets;
        underlying.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, assets, shares);
    }

    /* ============================================================
                       STRATEGY MANAGEMENT
       ============================================================ */

    function addStrategy(address strat, uint256 bps) external onlyOwner {
        require(bps <= MAX_BPS, "bad");
        require(IStrategy(strat).want() == address(underlying), "wrong token");

        uint256 sum = bps;
        for (uint256 i; i < strategies.length; ++i)
            sum += strategies[i].debtRatioBps;

        require(sum <= MAX_BPS, "ratio > 100%");

        strategies.push(Strategy({
            addr: strat,
            debtRatioBps: bps,
            totalDebt: 0,
            active: true
        }));

        indexOf[strat] = strategies.length;
        withdrawalQueue.push(strat);

        emit StrategyAdded(strat, bps);
    }

    function removeStrategy(address strat) external onlyOwner {
        uint256 idx = indexOf[strat];
        require(idx != 0, "no");
        idx--;

        Strategy storage s = strategies[idx];
        s.active = false;

        /* force pull all debt */
        if (s.totalDebt > 0) {
            uint256 pulled = IStrategy(strat).withdraw(s.totalDebt);
            if (pulled > s.totalDebt) pulled = s.totalDebt;

            s.totalDebt -= pulled;
            totalDebt -= pulled;
            totalIdle += pulled;
        }

        /* compact array */
        uint256 last = strategies.length - 1;
        if (idx != last) {
            strategies[idx] = strategies[last];
            indexOf[strategies[idx].addr] = idx + 1;
        }
        strategies.pop();
        delete indexOf[strat];

        /* remove from queue */
        uint256 q = withdrawalQueue.length;
        for (uint256 i; i < q; i++) {
            if (withdrawalQueue[i] == strat) {
                withdrawalQueue[i] = withdrawalQueue[q - 1];
                withdrawalQueue.pop();
                break;
            }
        }

        emit StrategyRemoved(strat);
    }

    /* ============================================================
                           REBALANCE ENGINE
       ============================================================ */

    function rebalance() external nonReentrant {
        _rebalance();
    }

    function _rebalance() internal {
        _pullOverweight();
        _pushUnderweight();
        emit Rebalanced();
    }

    function _pullOverweight() internal {
        uint256 ta = totalAssets();
        uint256 len = strategies.length;

        for (uint256 i; i < len; ++i) {
            Strategy storage s = strategies[i];
            if (!s.active || s.debtRatioBps == 0) continue;

            uint256 target = (ta * s.debtRatioBps) / MAX_BPS;

            if (s.totalDebt > target) {
                uint256 excess = s.totalDebt - target;

                uint256 got = IStrategy(s.addr).withdraw(excess);
                if (got > excess) got = excess;

                s.totalDebt -= got;
                totalDebt -= got;
                totalIdle += got;

                emit StrategyPull(s.addr, got);
            }
        }
    }

    function _pushUnderweight() internal {
        uint256 ta = totalAssets();
        if (ta == 0 || totalIdle == 0) return;

        uint256 len = strategies.length;

        for (uint256 i; i < len && totalIdle > 0; ++i) {
            Strategy storage s = strategies[i];
            if (!s.active || s.debtRatioBps == 0) continue;

            uint256 target = (ta * s.debtRatioBps) / MAX_BPS;

            if (s.totalDebt < target) {
                uint256 need = target - s.totalDebt;
                uint256 amt = need > totalIdle ? totalIdle : need;

                if (amt > 0) {
                    underlying.safeTransfer(s.addr, amt);
                    s.totalDebt += amt;
                    totalDebt += amt;
                    totalIdle -= amt;

                    emit StrategyPush(s.addr, amt);
                }
            }
        }
    }

    /* ============================================================
                    WITHDRAW QUEUE LOGIC
       ============================================================ */

    function _withdrawFromQueue(uint256 need) internal {
        uint256 len = withdrawalQueue.length;

        for (uint256 i; i < len && need > 0; ++i) {
            address strat = withdrawalQueue[i];
            uint256 idx = indexOf[strat];
            if (idx == 0) continue;
            idx--;

            Strategy storage s = strategies[idx];
            if (!s.active || s.totalDebt == 0) continue;

            uint256 req = s.totalDebt < need ? s.totalDebt : need;
            uint256 got = IStrategy(strat).withdraw(req);
            if (got > req) got = req;

            s.totalDebt -= got;
            totalDebt -= got;
            totalIdle += got;

            need -= got;
            emit StrategyPull(strat, got);
        }
    }

    /* ============================================================
                              ADMIN
       ============================================================ */

    function setDepositLimit(uint256 limit) external onlyOwner {
        depositLimit = limit;
    }

    function setEmergencyShutdown(bool flag) external onlyOwner {
        emergencyShutdown = flag;
        if (flag) _pause();
        else _unpause();
    }

    /* ============================================================
                              VIEW
       ============================================================ */

    function listStrategies()
        external
        view 
        returns (StrategyView[] memory out) 
    {
        uint256 len = strategies.length;
        out = new StrategyView[](len);

        for (uint256 i; i<len; ++i) {
            Strategy storage s = strategies[i];

            uint256 est = 0;
            if (!s.active) {
                try IStrategy(s.addr).estimatedTotalAssets() returns (uint256 r) {
                    est = r; 
                } catch {}
            }

            out[i] = StrategyView({
                addr: s.addr,
                active: s.active,
                debtRatioBps: s.debtRatioBps,
                totalDebt: s.totalDebt,
                estimatedAssets: est
            });
        }    
    }
}
s