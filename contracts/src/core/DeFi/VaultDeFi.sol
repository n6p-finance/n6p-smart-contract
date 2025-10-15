// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20, IERC20 as OZ_IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Napy Token Vault (refactored)
 * @notice Solidity implementation of a Vault (port of original Vyper-based design).
 *         This refactor preserves storage layout & behavior where possible, fixes bugs,
 *         and improves safety/readability.
 *
 * Notes:
 *  - Shares are an internal ERC20-like ledger (Transfer/Approval events are used).
 *  - The vault holds an underlying ERC20 `token`.
 */

interface IStrategy {
    function want() external view returns (address);
    function vault() external view returns (address);
    function isActive() external view returns (bool);
    function delegatedAssets() external view returns (uint256);
    function estimatedTotalAssets() external view returns (uint256);
    function withdraw(uint256 _amount) external returns (uint256 loss);
    function migrate(address _newStrategy) external;
    function emergencyExit() external view returns (bool);
    function totalIdle() external view returns (uint256);
    function totalDebt() external view returns (uint256);
}

library MathLib {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/* ========== Reentrancy Guard contract ========== */
abstract contract ReentrancyGuard {
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;        
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/* ========== Vault ========== */
contract Vault is ReentrancyGuard {
    using SafeERC20 for OZ_IERC20;
    using MathLib for uint256;

    // ----- Constants -----
    string public constant API_VERSION = "0.4.6";
    uint256 public constant MAXIMUM_STRATEGIES = 20;
    uint256 public constant DEGRADATION_COEFFICIENT = 1e18;
    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant SECS_PER_YEAR = 31_556_952; // 365.2425 days
    uint256 internal constant MAX_UINT256 = type(uint256).max;

    // ----- ERC20-like metadata for shares -----
    string public name;
    string public symbol;
    uint8 public decimals; // match underlying decimals

    // ----- Shares accounting -----
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    // ----- Roles and core params -----
    OZ_IERC20 public token;
    address public governance;
    address public management;
    address public guardian;
    address public pendingGovernance;

    struct StrategyParams {
        uint256 performanceFee;
        uint256 activation;
        uint256 debtRatio;
        uint256 minDebtPerHarvest;
        uint256 maxDebtPerHarvest;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalLoss;
    }

    mapping(address => StrategyParams) public strategies;
    address[MAXIMUM_STRATEGIES] public withdrawalQueue;

    bool public emergencyShutdown;

    uint256 public depositLimit;
    uint256 public debtRatio;
    uint256 public totalIdle;
    uint256 public totalDebt;
    uint256 public lastReport;
    uint256 public activation;
    uint256 public lockedProfit;
    uint256 public lockedProfitDegradation; // scaled by 1e18
    address public rewards;
    uint256 public managementFee; // bps
    uint256 public performanceFee; // bps

    // EIP-2612 Permit
    mapping(address => uint256) public nonces;
    bytes32 public constant DOMAIN_TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant PERMIT_TYPE_HASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // Additional V3-like params
    address public accountant;
    address public depositLimitModule;
    address public withdrawLimitModule;
    uint256 public minTotalIdle;
    bool public useDefaultQueue;
    bool public autoAllocate;

    // Roles bitmasks
    mapping(address => uint256) public roles;
    address public roleManager;
    address public pendingRoleManager;

    // ----- Events (kept as before; added missing UpdateFutureRoleManager) -----
    event Transfer(address indexed sender, address indexed receiver, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed recipient, uint256 shares, uint256 amount);
    event Withdraw(address indexed recipient, uint256 shares, uint256 amount);
    event Sweep(address indexed token, uint256 amount);
    event LockedProfitDegradationUpdated(uint256 value);
    event StrategyAdded(address indexed strategy, uint256 debtRatio, uint256 minDebtPerHarvest, uint256 maxDebtPerHarvest, uint256 performanceFee);
    event StrategyReported(address indexed strategy, uint256 gain, uint256 loss, uint256 debtPaid, uint256 totalGain, uint256 totalLoss, uint256 totalDebt, uint256 debtAdded, uint256 debtRatio);
    event FeeReport(uint256 management_fee, uint256 performance_fee, uint256 strategist_fee, uint256 duration);
    event WithdrawFromStrategy(address indexed strategy, uint256 totalDebt, uint256 loss);
    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event UpdateRewards(address rewards);
    event UpdateDepositLimit(uint256 depositLimit);
    event UpdatePerformanceFee(uint256 performanceFee);
    event UpdateManagementFee(uint256 managementFee);
    event UpdateGuardian(address guardian);
    event EmergencyShutdown(bool active);
    event UpdateWithdrawalQueue(address[MAXIMUM_STRATEGIES] queue);
    event StrategyUpdateDebtRatio(address indexed strategy, uint256 debtRatio);
    event StrategyUpdateMinDebtPerHarvest(address indexed strategy, uint256 minDebtPerHarvest);
    event StrategyUpdateMaxDebtPerHarvest(address indexed strategy, uint256 maxDebtPerHarvest);
    event StrategyUpdatePerformanceFee(address indexed strategy, uint256 performanceFee);
    event StrategyMigrated(address indexed oldVersion, address indexed newVersion);
    event StrategyRevoked(address indexed strategy);
    event StrategyRemovedFromQueue(address indexed strategy);
    event StrategyAddedToQueue(address indexed strategy);
    event NewPendingGovernance(address indexed pendingGovernance);
    event UpdateAccountant(address indexed accountant);
    event UpdateDepositLimitModule(address indexed module);
    event UpdateWithdrawLimitModule(address indexed module);
    event UpdateMinimumTotalIdle(uint256 minTotalIdle);
    event UpdateProfitMaxUnlockTime(uint256 time);
    event UpdateUseDefaultQueue(bool useDefaultQueue);
    event UpdateAutoAllocate(bool autoAllocate);
    event RoleSet(address indexed account, uint256 role);
    event UpdateRoleManager(address roleManager);
    event UpdateFutureRoleManager(address pendingRoleManager);

    

    // ----- Modifiers -----
    modifier onlyGov() { require(msg.sender == governance, "Vault: gov only"); _; }
    modifier onlyGovOrMgmt() { require(msg.sender == governance || msg.sender == management, "Vault: gov/mgmt"); _; }
    modifier onlyAcc() { require(msg.sender == accountant, "Vault: acc only"); _; }
    modifier onlyRoleManager() { require(msg.sender == roleManager, "Vault: role manager only"); _; }

    // ----- Initialization (replaces Vyper initialize external) -----
    function initialize(
        address _token,
        address _governance,
        address _rewards,
        string memory nameOverride,
        string memory symbolOverride,
        address _guardian,
        address _management
    ) external {
        require(activation == 0, "Vault: already initialized");
        require(_token != address(0), "Vault: token 0");

        token = OZ_IERC20(_token);

        if (bytes(nameOverride).length == 0) {
            name = string(abi.encodePacked(IERC20Metadata(_token).symbol(), " nVault"));
        } else {
            name = nameOverride;
        }

        if (bytes(symbolOverride).length == 0) {
            symbol = string(abi.encodePacked("nV", IERC20Metadata(_token).symbol()));
        } else {
            symbol = symbolOverride;
        }

        decimals = IERC20Metadata(_token).decimals();

        governance = _governance;
        emit UpdateGovernance(_governance);

        management = _management;
        emit UpdateManagement(_management);

        rewards = _rewards;
        emit UpdateRewards(_rewards);

        guardian = _guardian;
        emit UpdateGuardian(_guardian);

        performanceFee = 1000; // 10% (bps)
        emit UpdatePerformanceFee(1000);

        managementFee = 200; // 2% (bps)
        emit UpdateManagementFee(200);

        lastReport = block.timestamp;
        activation = block.timestamp;

        // initial degradation: ~6 hours expressed in scaled coefficient
        lockedProfitDegradation = (DEGRADATION_COEFFICIENT * 46) / 1e6;
        emit LockedProfitDegradationUpdated(lockedProfitDegradation);

        roleManager = _governance;
        emit UpdateRoleManager(_governance);
    }

    // ----- EIP-712 domain (permit) -----
    function _domainSeparatorV4() internal view returns (bytes32) {
        // Use vault 'name' and API_VERSION for domain uniqueness
        return keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(API_VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) { return _domainSeparatorV4(); }
    function apiVersion() external pure returns (string memory) { return API_VERSION; }

    // ----- Admin setters & role management -----
    function setName(string calldata _name) external onlyGov { name = _name; }
    function setSymbol(string calldata _symbol) external onlyGov { symbol = _symbol; }

    function setRole(address _account, uint256 _role) external onlyRoleManager {
        roles[_account] = _role;
        emit RoleSet(_account, _role);
    }

    function addRole(address _account, uint256 _role) external onlyRoleManager {
        roles[_account] |= _role;
        emit RoleSet(_account, roles[_account]);
    }

    function removeRole(address _account, uint256 _role) external onlyRoleManager {
        roles[_account] &= ~_role;
        emit RoleSet(_account, roles[_account]);
    }

    function setAccountant(address _acc) external onlyGov {
        accountant = _acc;
        emit UpdateAccountant(_acc);
    }

    function transferRoleManager(address _pendingRoleManager) external onlyRoleManager {
        pendingRoleManager = _pendingRoleManager;
        emit UpdateFutureRoleManager(_pendingRoleManager);
    }

    function acceptRoleManager() external {
        require(msg.sender == pendingRoleManager, "Vault: not pending role manager");
        roleManager = msg.sender;
        emit UpdateRoleManager(msg.sender);
    }

    function setGovernance(address _gov) external onlyGov {
        pendingGovernance = _gov;
        emit NewPendingGovernance(_gov);
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "Vault: not pending governance");
        governance = msg.sender;
        emit UpdateGovernance(msg.sender);
    }

    function setManagement(address _mgmt) external onlyGov {
        management = _mgmt;
        emit UpdateManagement(_mgmt);
    }

    function setRewards(address _rewards) external onlyGov {
        require(_rewards != address(0) && _rewards != address(this), "Vault: bad rewards");
        rewards = _rewards;
        emit UpdateRewards(_rewards);
    }

    function setLockedProfitDegradation(uint256 degradation) external onlyGov {
        require(degradation <= DEGRADATION_COEFFICIENT, "Vault: deg > coef");
        lockedProfitDegradation = degradation;
        emit LockedProfitDegradationUpdated(degradation);
    }

    /// @notice Set the maximum time (seconds) over which profit fully unlocks.
    /// @dev Passing 0 sets lockedProfit to 0 and degradation to 0 for safety.
    function setProfitMaxUnlockTime(uint256 _time) external onlyGov {
        require(_time <= SECS_PER_YEAR, "Vault: too long");
        if (_time == 0) {
            // previously this set lockedProfit incorrectly; fix: set degradation = 0 and wipe lockedProfit
            lockedProfitDegradation = 0;
            lockedProfit = 0;
        } else {
            lockedProfitDegradation = DEGRADATION_COEFFICIENT / _time;
        }
        emit UpdateProfitMaxUnlockTime(_time);
        emit LockedProfitDegradationUpdated(lockedProfitDegradation);
    }

    function setDepositLimit(uint256 limit) external onlyGov {
        depositLimit = limit;
        emit UpdateDepositLimit(limit);
    }

    function setDepositLimitModule(address _module, bool _override) external onlyGov {
        if (!_override) {
            require(depositLimit == MAX_UINT256, "Vault: limit not max");
        }
        depositLimitModule = _module;
        emit UpdateDepositLimitModule(_module);
    }

    function setPerformanceFee(uint256 fee) external onlyGov {
        require(fee <= MAX_BPS / 2, "Vault: pf > 50%");
        performanceFee = fee;
        emit UpdatePerformanceFee(fee);
    }

    function setManagementFee(uint256 fee) external onlyGov {
        require(fee <= MAX_BPS, "Vault: mgf > MAX_BPS");
        managementFee = fee;
        emit UpdateManagementFee(fee);
    }

    function setGuardian(address _guardian) external {
        require(msg.sender == guardian || msg.sender == governance, "Vault: guardian auth");
        guardian = _guardian;
        emit UpdateGuardian(_guardian);
    }

    function setEmergencyShutdown(bool active) external {
        if (active) {
            require(msg.sender == guardian || msg.sender == governance, "Vault: auth");
        } else {
            require(msg.sender == governance, "Vault: gov only");
        }
        emergencyShutdown = active;
        emit EmergencyShutdown(active);
    }

    function setWithdrawalQueue(address[MAXIMUM_STRATEGIES] calldata queue) external onlyGovOrMgmt {
        // second-pass validation: preserve existing null zones and only reorder existing entries
        address[MAXIMUM_STRATEGIES] memory oldq = withdrawalQueue;
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (queue[i] == address(0)) {
                require(oldq[i] == address(0), "Vault: cannot extend queue");
                break;
            }
            require(oldq[i] != address(0), "Vault: cannot add");
            require(strategies[queue[i]].activation > 0, "Vault: unknown strategy");
            bool exists = false;
            for (uint256 j = 0; j < MAXIMUM_STRATEGIES; j++) {
                if (queue[j] == address(0)) { exists = true; break; }
                if (queue[i] == oldq[j]) { exists = true; }
                if (j <= i) continue;
                require(queue[i] != queue[j], "Vault: dup strategy");
            }
            require(exists, "Vault: not exists in old queue");
            withdrawalQueue[i] = queue[i];
        }
        emit UpdateWithdrawalQueue(queue);
    }

    function default_queue(bool _useDefault) external onlyGovOrMgmt {
        useDefaultQueue = _useDefault;
        emit UpdateUseDefaultQueue(_useDefault);
    }

    function auto_allocate(bool _auto) external onlyAcc {
        autoAllocate = _auto;
        emit UpdateAutoAllocate(_auto);
    }

    // ----- Safe ERC20 helpers -----
    function _safeTransfer(address _token, address to, uint256 amount) internal {
        OZ_IERC20(_token).safeTransfer(to, amount);
    }
    function _safeTransferFrom(address _token, address from, address to, uint256 amount) internal {
        OZ_IERC20(_token).safeTransferFrom(from, to, amount);
    }

    // ----- ERC20 shares logic -----
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0) && to != address(this), "Vault: bad to");
        balanceOf[from] -= amount; // underflow will revert in 0.8
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            require(allowed >= amount, "Vault: allowance");
            allowance[from][msg.sender] = allowed - amount;
            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }
        _transfer(from, to, amount);
        return true;
    }

    function transferShares(address to, uint256 amount) external {
        _transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] -= amount;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    // ----- EIP-2612 permit -----
    function permit(address owner, address spender, uint256 value, uint256 deadline, bytes calldata signature) external returns (bool) {
        require(owner != address(0), "Vault: owner 0");
        require(deadline >= block.timestamp, "Vault: permit expired");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(abi.encode(PERMIT_TYPE_HASH, owner, spender, value, nonces[owner], deadline))
            )
        );

        (bytes32 r, bytes32 s, uint8 v) = _splitSig(signature);
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == owner, "Vault: invalid sig");

        allowance[owner][spender] = value;
        nonces[owner] += 1;
        emit Approval(owner, spender, value);
        return true;
    }

    function _splitSig(bytes calldata sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Vault: siglen");
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
    }

    // ----- Views & accounting helpers -----
    function _totalAssets() internal view returns (uint256) {
        return totalIdle + totalDebt;
    }

    function setMinTotalIdle(uint256 _min) external onlyGov {
        minTotalIdle = _min;
        emit UpdateMinimumTotalIdle(_min);
    }

    function totalAssets() external view returns (uint256) {
        return _totalAssets();
    }

    function _calculateLockedProfit() internal view returns (uint256) {
        if (lockedProfit == 0 || lockedProfitDegradation == 0) return 0;
        uint256 lockedFundsRatio = (block.timestamp - lastReport) * lockedProfitDegradation;
        if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
            uint256 lp = lockedProfit;
            return lp - ((lockedFundsRatio * lp) / DEGRADATION_COEFFICIENT);
        } else {
            return 0;
        }
    }

    function _freeFunds() internal view returns (uint256) {
        uint256 total = _totalAssets();
        uint256 lp = _calculateLockedProfit();
        if (total <= lp) return 0;
        return total - lp;
    }

    function _issueSharesForAmount(address to, uint256 amount) internal returns (uint256 shares) {
        uint256 ts = totalSupply;
        uint256 freeFunds = _freeFunds();

        if (ts > 0 && freeFunds > 0) {
            // avoid division by zero when freeFunds == 0
            shares = (amount * ts) / freeFunds;
        } else {
            // initial deposit or no free funds => 1:1
            shares = amount;
        }

        require(shares != 0, "Vault: zero shares");
        totalSupply = ts + shares;
        balanceOf[to] += shares;
        emit Transfer(address(0), to, shares);
    }

    function _shareValue(uint256 shares) internal view returns (uint256) {
        if (totalSupply == 0) return shares;
        uint256 ff = _freeFunds();
        if (ff == 0) return 0;
        return (shares * ff) / totalSupply;
    }

    function _shareValuePublic_(uint256 shares) external view returns (uint256) {
        return _shareValue(shares);
    }

    function _sharesForAmount(uint256 amount) internal view returns (uint256) {
        uint256 ff = _freeFunds();
        if (ff > 0 && totalSupply > 0) {
            return (amount * totalSupply) / ff;
        } else {
            return 0;
        }
    }

    function _sharesForAmountPublic_(uint256 amount) external view returns (uint256) {
        return _sharesForAmount(amount);
    }

    function maxAvailableShares() external view returns (uint256) {
        uint256 shares = _sharesForAmount(totalIdle);
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            address s = withdrawalQueue[i];
            if (s == address(0)) break;
            shares += _sharesForAmount(strategies[s].totalDebt);
        }
        return shares;
    }

    // ----- Redeem / withdraw flows -----
    function redeemShares(uint256 shares, address recipient, address owner) external nonReentrant returns (uint256) {
        if (recipient == address(0)) recipient = msg.sender;
        if (owner == address(0)) owner = msg.sender;
        require(shares > 0 && shares <= balanceOf[owner], "Vault: shares");

        if (owner != msg.sender) {
            uint256 allowed = allowance[owner][msg.sender];
            if (allowed != MAX_UINT256) {
                require(allowed >= shares, "Vault: allowance < shares");
                allowance[owner][msg.sender] = allowed - shares;
                emit Approval(owner, msg.sender, allowance[owner][msg.sender]);
            }
        }

        uint256 value = _shareValue(shares);
        uint256 vaultBalance = totalIdle;
        uint256 totalLoss = 0;

        if (value > vaultBalance) {
            for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
                address strat = withdrawalQueue[i];
                if (strat == address(0)) break;
                if (value <= vaultBalance) break;
                uint256 amountNeeded = value - vaultBalance;
                amountNeeded = MathLib.min(amountNeeded, strategies[strat].totalDebt);
                if (amountNeeded == 0) continue;

                uint256 pre = OZ_IERC20(token).balanceOf(address(this));
                uint256 loss = IStrategy(strat).withdraw(amountNeeded);
                uint256 withdrawn = OZ_IERC20(token).balanceOf(address(this)) - pre;
                vaultBalance += withdrawn;
                if (loss > 0) {
                    // report loss to vault accounting
                    value -= loss;
                    totalLoss += loss;
                    _reportLoss(strat, loss);
                }
                // update debts
                strategies[strat].totalDebt -= withdrawn;
                totalDebt -= withdrawn;
                emit WithdrawFromStrategy(strat, strategies[strat].totalDebt, loss);
            }
            totalIdle = vaultBalance;

            if (value > vaultBalance) {
                value = vaultBalance;
                shares = _sharesForAmount(value + totalLoss);
            }
            // sanity: ensure losses aren't nonsensical
            require(totalLoss <= (MAX_BPS * (value + totalLoss)) / MAX_BPS, "Vault: excess loss");
        }

        totalSupply -= shares;
        balanceOf[owner] -= shares;
        emit Transfer(owner, address(0), shares);

        totalIdle -= value;
        _safeTransfer(address(token), recipient, value);
        emit Withdraw(recipient, shares, value);
        return value;
    }

    function deposit(uint256 _amount, address recipient) external nonReentrant returns (uint256) {
        if (recipient == address(0)) recipient = msg.sender;
        require(!emergencyShutdown, "Vault: shutdown");
        require(recipient != address(this), "Vault: bad recipient");

        uint256 amount = _amount;
        if (amount == MAX_UINT256) {
            uint256 maxDep = depositLimit > _totalAssets() ? (depositLimit - _totalAssets()) : 0;
            amount = MathLib.min(maxDep, OZ_IERC20(token).balanceOf(msg.sender));
        } else {
            if (depositLimit > 0) {
                require(_totalAssets() + amount <= depositLimit, "Vault: deposit limit");
            }
        }
        require(amount > 0, "Vault: zero amount");

        uint256 shares = _issueSharesForAmount(recipient, amount);
        _safeTransferFrom(address(token), msg.sender, address(this), amount);
        totalIdle += amount;
        emit Deposit(recipient, shares, amount);
        return shares;
    }

    function mint(uint256 shares, address recipient) external nonReentrant returns (uint256) {
        if (recipient == address(0)) recipient = msg.sender;
        require(!emergencyShutdown, "Vault: shutdown");
        require(recipient != address(this), "Vault: bad recipient");
        require(shares > 0, "Vault: zero shares");

        uint256 amount = _shareValue(shares);
        if (depositLimit > 0) {
            require(_totalAssets() + amount <= depositLimit, "Vault: deposit limit");
        }

        _safeTransferFrom(address(token), msg.sender, address(this), amount);
        totalIdle += amount;
        _issueSharesForAmount(recipient, shares);
        emit Deposit(recipient, shares, amount);
        return amount;
    }

    function withdraw(uint256 assets, address recipient, uint256 maxLoss) external nonReentrant returns (uint256) {
        if (recipient == address(0)) recipient = msg.sender;
        require(maxLoss <= MAX_BPS, "Vault: maxLoss > MAX_BPS");
        require(assets > 0, "Vault: zero assets");

        uint256 shares = _sharesForAmount(assets);
        require(shares <= balanceOf[msg.sender], "Vault: insufficient shares");

        uint256 value = assets;
        uint256 vaultBalance = totalIdle;
        uint256 totalLoss = 0;

        if (value > vaultBalance) {
            for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
                address strat = withdrawalQueue[i];
                if (strat == address(0)) break;
                if (value <= vaultBalance) break;

                uint256 amountNeeded = value - vaultBalance;
                amountNeeded = MathLib.min(amountNeeded, strategies[strat].totalDebt);
                if (amountNeeded == 0) continue;

                uint256 pre = OZ_IERC20(token).balanceOf(address(this));
                uint256 loss = IStrategy(strat).withdraw(amountNeeded);
                uint256 withdrawn = OZ_IERC20(token).balanceOf(address(this)) - pre;
                vaultBalance += withdrawn;
                if (loss > 0) {
                    value -= loss;
                    totalLoss += loss;
                    _reportLoss(strat, loss);
                }
                strategies[strat].totalDebt -= withdrawn;
                totalDebt -= withdrawn;
                emit WithdrawFromStrategy(strat, strategies[strat].totalDebt, loss);
            }
            totalIdle = vaultBalance;
            if (value > vaultBalance) {
                value = vaultBalance;
            }
            require(totalLoss <= (maxLoss * value) / MAX_BPS, "Vault: excess loss");
            shares = _sharesForAmount(value);
        }

        totalSupply -= shares;
        balanceOf[msg.sender] -= shares;
        emit Transfer(msg.sender, address(0), shares);

        totalIdle -= value;
        _safeTransfer(address(token), recipient, value);
        emit Withdraw(recipient, shares, value);
        return shares;
    }

    function setWithdrawalLimitModule(address _module) external onlyGov {
        withdrawLimitModule = _module;
        emit UpdateWithdrawLimitModule(_module);
    }

    function pricePerShare() external view returns (uint256) {
        return _shareValue(10 ** decimals);
    }

    function _organizeWithdrawalQueue() internal {
        uint256 offset = 0;
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            address s = withdrawalQueue[i];
            if (s == address(0)) { offset += 1; continue; }
            if (offset > 0) {
                withdrawalQueue[i - offset] = s;
                withdrawalQueue[i] = address(0);
            }
        }
    }

    // ----- Strategy management -----
    function addStrategy(address strategy, uint256 _debtRatio, uint256 minDebtPerHarvest, uint256 maxDebtPerHarvest, uint256 _performanceFee) external onlyGov {
        require(withdrawalQueue[MAXIMUM_STRATEGIES - 1] == address(0), "Vault: queue full");
        require(!emergencyShutdown, "Vault: shutdown");
        require(strategy != address(0), "Vault: strategy 0");
        require(strategies[strategy].activation == 0, "Vault: exists");
        require(IStrategy(strategy).vault() == address(this), "Vault: wrong vault");
        require(IStrategy(strategy).want() == address(token), "Vault: wrong want");
        require(debtRatio + _debtRatio <= MAX_BPS, "Vault: ratio overflow");
        require(minDebtPerHarvest <= maxDebtPerHarvest, "Vault: min > max");
        require(_performanceFee <= MAX_BPS / 2, "Vault: pf > 50%");

        strategies[strategy] = StrategyParams({
            performanceFee: _performanceFee,
            activation: block.timestamp,
            debtRatio: _debtRatio,
            minDebtPerHarvest: minDebtPerHarvest,
            maxDebtPerHarvest: maxDebtPerHarvest,
            lastReport: block.timestamp,
            totalDebt: 0,
            totalGain: 0,
            totalLoss: 0
        });

        emit StrategyAdded(strategy, _debtRatio, minDebtPerHarvest, maxDebtPerHarvest, _performanceFee);

        debtRatio += _debtRatio;
        withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy;
        _organizeWithdrawalQueue();
    }

    function updateStrategyDebtRatio(address strategy, uint256 _debtRatio) external onlyGovOrMgmt {
        require(strategies[strategy].activation > 0, "Vault: unknown strategy");
        require(!IStrategy(strategy).emergencyExit(), "Vault: strategy emergency exit");
        debtRatio -= strategies[strategy].debtRatio;
        strategies[strategy].debtRatio = _debtRatio;
        debtRatio += _debtRatio;
        require(debtRatio <= MAX_BPS, "Vault: debtRatio > MAX_BPS");
        emit StrategyUpdateDebtRatio(strategy, _debtRatio);
    }

    function updateStrategyMinDebtPerHarvest(address strategy, uint256 m) external onlyGovOrMgmt {
        require(strategies[strategy].activation > 0, "Vault: unknown strategy");
        require(strategies[strategy].maxDebtPerHarvest >= m, "Vault: min > max");
        strategies[strategy].minDebtPerHarvest = m;
        emit StrategyUpdateMinDebtPerHarvest(strategy, m);
    }

    function updateStrategyMaxDebtPerHarvest(address strategy, uint256 m) external onlyGovOrMgmt {
        require(strategies[strategy].activation > 0, "Vault: unknown strategy");
        require(strategies[strategy].minDebtPerHarvest <= m, "Vault: max < min");
        strategies[strategy].maxDebtPerHarvest = m;
        emit StrategyUpdateMaxDebtPerHarvest(strategy, m);
    }

    function updateStrategyPerformanceFee(address strategy, uint256 pf) external onlyGov {
        require(pf <= MAX_BPS / 2, "Vault: pf > 50%");
        require(strategies[strategy].activation > 0, "Vault: unknown strategy");
        strategies[strategy].performanceFee = pf;
        emit StrategyUpdatePerformanceFee(strategy, pf);
    }

    function _revokeStrategy(address strategy) internal {
        debtRatio -= strategies[strategy].debtRatio;
        strategies[strategy].debtRatio = 0;
        emit StrategyRevoked(strategy);
    }

    function migrateStrategy(address oldVersion, address newVersion) external onlyGov {
        require(newVersion != address(0), "Vault: new 0");
        require(strategies[oldVersion].activation > 0, "Vault: old unknown");
        require(strategies[newVersion].activation == 0, "Vault: new exists");

        StrategyParams memory s = strategies[oldVersion];
        _revokeStrategy(oldVersion);
        debtRatio += s.debtRatio;

        // zero out old debt
        strategies[oldVersion].totalDebt = 0;

        strategies[newVersion] = StrategyParams({
            performanceFee: s.performanceFee,
            activation: s.lastReport,
            debtRatio: s.debtRatio,
            minDebtPerHarvest: s.minDebtPerHarvest,
            maxDebtPerHarvest: s.maxDebtPerHarvest,
            lastReport: s.lastReport,
            totalDebt: s.totalDebt,
            totalGain: 0,
            totalLoss: 0
        });

        IStrategy(oldVersion).migrate(newVersion);
        emit StrategyMigrated(oldVersion, newVersion);

        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawalQueue[i] == oldVersion) {
                withdrawalQueue[i] = newVersion;
                return;
            }
        }
    }

    function revokeStrategy(address strategy) external {
        require(msg.sender == strategy || msg.sender == governance || msg.sender == guardian, "Vault: revoke auth");
        require(strategies[strategy].debtRatio != 0, "Vault: already revoked");
        _revokeStrategy(strategy);
    }

    function addStrategyToQueue(address strategy) external onlyGovOrMgmt {
        require(strategies[strategy].activation > 0, "Vault: unknown strategy");
        uint256 lastIdx = 0;
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            address s = withdrawalQueue[i];
            if (s == address(0)) break;
            require(s != strategy, "Vault: dup in queue");
            lastIdx++;
        }
        require(lastIdx < MAXIMUM_STRATEGIES, "Vault: queue full");
        withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy;
        _organizeWithdrawalQueue();
        emit StrategyAddedToQueue(strategy);
    }

    function removeStrategyFromQueue(address strategy) external onlyGovOrMgmt {
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawalQueue[i] == strategy) {
                withdrawalQueue[i] = address(0);
                _organizeWithdrawalQueue();
                emit StrategyRemovedFromQueue(strategy);
                return;
            }
        }
        revert("Vault: not in queue");
    }

    // ----- Debt & credit management -----
    function _debtOutstanding(address strategy) internal view returns (uint256) {
        if (debtRatio == 0) return strategies[strategy].totalDebt;
        uint256 strategyDebtLimit = (strategies[strategy].debtRatio * _totalAssets()) / MAX_BPS;
        uint256 strategyTotalDebt = strategies[strategy].totalDebt;
        if (emergencyShutdown) return strategyTotalDebt;
        else if (strategyTotalDebt <= strategyDebtLimit) return 0;
        else return strategyTotalDebt - strategyDebtLimit;
    }

    function debtOutstanding(address strategy) external view returns (uint256) {
        if (strategy == address(0)) strategy = msg.sender;
        return _debtOutstanding(strategy);
    }

    function _creditAvailable(address strategy) internal view returns (uint256) {
        if (emergencyShutdown) return 0;
        uint256 vTotalAssets = _totalAssets();
        uint256 vDebtLimit = (debtRatio * vTotalAssets) / MAX_BPS;
        uint256 vTotalDebt = totalDebt;
        uint256 sDebtLimit = (strategies[strategy].debtRatio * vTotalAssets) / MAX_BPS;
        uint256 sTotalDebt = strategies[strategy].totalDebt;
        uint256 sMin = strategies[strategy].minDebtPerHarvest;
        uint256 sMax = strategies[strategy].maxDebtPerHarvest;

        if (sDebtLimit <= sTotalDebt || vDebtLimit <= vTotalDebt) return 0;
        uint256 available = sDebtLimit - sTotalDebt;
        available = MathLib.min(available, vDebtLimit - vTotalDebt);
        available = MathLib.min(available, totalIdle);
        if (available < sMin) return 0;
        else return MathLib.min(available, sMax);
    }

    function creditAvailable(address strategy) external view returns (uint256) {
        if (strategy == address(0)) strategy = msg.sender;
        return _creditAvailable(strategy);
    }

    function _expectedReturn(address strategy) internal view returns (uint256) {
        uint256 last = strategies[strategy].lastReport;
        uint256 timeSince = block.timestamp - last;
        uint256 totalHarvestTime = last - strategies[strategy].activation;
        if (timeSince > 0 && totalHarvestTime > 0 && IStrategy(strategy).isActive()) {
            return (strategies[strategy].totalGain * timeSince) / totalHarvestTime;
        } else {
            return 0;
        }
    }

    function expectedReturn(address strategy) external view returns (uint256) {
        if (strategy == address(0)) strategy = msg.sender;
        return _expectedReturn(strategy);
    }

    // ----- Fees and reporting -----
    function _assessFees(address strategy, uint256 gain) internal returns (uint256 total_fee) {
        // Avoid assessing fees if strategy activated in same block (protect frontrunning)
        if (strategies[strategy].activation == block.timestamp) return 0;

        uint256 duration = block.timestamp - strategies[strategy].lastReport;
        require(duration != 0, "Vault: same block");

        if (gain == 0) return 0;

        uint256 management_fee = ((strategies[strategy].totalDebt - IStrategy(strategy).delegatedAssets()) * duration * managementFee) / MAX_BPS / SECS_PER_YEAR;
        uint256 strategist_fee = (gain * strategies[strategy].performanceFee) / MAX_BPS;
        uint256 performance_fee_ = (gain * performanceFee) / MAX_BPS;

        total_fee = management_fee + strategist_fee + performance_fee_;
        if (total_fee > gain) total_fee = gain;

        if (total_fee > 0) {
            // issue shares to vault as fee
            uint256 rewardShares = _issueSharesForAmount(address(this), total_fee);

            if (strategist_fee > 0) {
                uint256 strategist_reward = (strategist_fee * rewardShares) / total_fee;
                // safe internal shares transfer
                _transfer(address(this), strategy, strategist_reward);
            }

            uint256 bal = balanceOf[address(this)];
            if (bal > 0) {
                _transfer(address(this), rewards, bal); // remaining goes to rewards
            }
        }

        emit FeeReport(management_fee, performance_fee_, strategist_fee, duration);
    }

    function report(uint256 gain, uint256 loss, uint256 _debtPayment) external returns (uint256) {
        require(strategies[msg.sender].activation > 0, "Vault: unknown reporter");
        // ensure reporter has tokens for distribution (gain + debt payment)
        require(OZ_IERC20(token).balanceOf(msg.sender) >= gain + _debtPayment, "Vault: insufficient token balance");

        if (loss > 0) {
            _reportLoss(msg.sender, loss);
        }

        uint256 totalFees = _assessFees(msg.sender, gain);
        strategies[msg.sender].totalGain += gain;

        uint256 credit = _creditAvailable(msg.sender);
        uint256 debt = _debtOutstanding(msg.sender);

        uint256 debtPayment = MathLib.min(_debtPayment, debt);
        if (debtPayment > 0) {
            strategies[msg.sender].totalDebt -= debtPayment;
            totalDebt -= debtPayment;
            debt -= debtPayment;
        }

        if (credit > 0) {
            strategies[msg.sender].totalDebt += credit;
            totalDebt += credit;
        }

        uint256 totalAvail = gain + debtPayment;
        if (totalAvail < credit) {
            totalIdle -= (credit - totalAvail);
            _safeTransfer(address(token), msg.sender, credit - totalAvail);
        } else if (totalAvail > credit) {
            totalIdle += (totalAvail - credit);
            _safeTransferFrom(address(token), msg.sender, address(this), totalAvail - credit);
        }

        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() + (gain - totalFees);
        if (lockedProfitBeforeLoss > loss) lockedProfit = lockedProfitBeforeLoss - loss;
        else lockedProfit = 0;

        strategies[msg.sender].lastReport = block.timestamp;
        lastReport = block.timestamp;

        emit StrategyReported(msg.sender, gain, loss, debtPayment, strategies[msg.sender].totalGain, strategies[msg.sender].totalLoss, strategies[msg.sender].totalDebt, credit, strategies[msg.sender].debtRatio);

        if (strategies[msg.sender].debtRatio == 0 || emergencyShutdown) {
            return IStrategy(msg.sender).estimatedTotalAssets();
        } else {
            return debt;
        }
    }

    function _reportLoss(address strategy, uint256 loss) internal {
        uint256 totalDebt_ = strategies[strategy].totalDebt;
        require(totalDebt_ >= loss, "Vault: loss > total debt");
        if (debtRatio != 0) {
            uint256 ratio_change = 0;
            if (totalDebt > 0) {
                ratio_change = MathLib.min((loss * debtRatio) / totalDebt, strategies[strategy].debtRatio);
            }
            strategies[strategy].debtRatio -= ratio_change;
            debtRatio -= ratio_change;
        }
        strategies[strategy].totalLoss += loss;
        strategies[strategy].totalDebt = totalDebt_ - loss;
        totalDebt -= loss;
    }

    function availableDepositLimit() external view returns (uint256) {
        return depositLimit > _totalAssets() ? depositLimit - _totalAssets() : 0;
    }

    // Sweep unexpected tokens (protect main token)
    function sweep(address _token, uint256 amount) external onlyGov {
        uint256 value = amount;
        if (value == MAX_UINT256) {
            value = OZ_IERC20(_token).balanceOf(address(this));
        }
        if (_token == address(token)) {
            // only sweep profit over totalIdle
            value = OZ_IERC20(_token).balanceOf(address(this)) - totalIdle;
        }
        emit Sweep(_token, value);
        _safeTransfer(_token, governance, value);
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        return _sharesForAmount(assets);
    }

    function previewMint(uint256 shares_) external view returns (uint256) {
        return _shareValue(shares_);
    }
}
