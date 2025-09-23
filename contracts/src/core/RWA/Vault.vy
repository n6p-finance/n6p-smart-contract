"""
@title Napfi Token Vault (ERC-7540)
@license GNU AGPLv3
@author rudeus33
@notice
    Napfi Token Vault (ERC-7540) is async 
"""

"""
@dev Keep:
    NOTE: IEP-712 is implementing ERC-4626 without any signature so it is gasless
@dev Questions:
    NOTE: What's the difference between ERC-7540 and ERC-4626?
    ERC-7540 is async, ERC-4626 is sync.

    NOTE: What's the difference between async and sync?

    NOTE: What's the different on how to implement async and sync?

@what need to be updated in vault so it matches ERC-7540 specification:
    NOTE: 1. ERC-7540 
    

"""

API_VERSION: constant(string[28]) = "0.4.6"

from vyper.interfaces import ERC20

implements: ERC20

interface DetailedERC20:
    def name() -> String[42]: view
    def symbol() -> String[20]: view
    def decimals() -> uint256: view

# RWA Strategy
interface Strategy:
    def want() -> address: view
    def vault() -> address: view
    def isActive() -> bool: view
    def delegatedAssets() -> uint256: view
    def estimatedTotalAssets() -> uint256: view
    def withdraw(_amount: uint256) -> uint256: nonpayable
    def migrate(_newStrategy: address): nonpayable
    def emergencyExit() -> bool: view

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

token: public(ERC20)
governance: public(address)
management: public(address)
guardian: public(address)
pendingGovernance: address

struct StrategyParams:
    performanceFee: uint256  # Strategist's fee (basis points)
    activation: uint256  # Activation block.timestamp
    debtRatio: uint256  # Maximum borrow amount (in BPS of total assets)
    minDebtPerHarvest: uint256  # Lower limit on the increase of debt since last harvest
    maxDebtPerHarvest: uint256  # Upper limit on the increase of debt since last harvest
    lastReport: uint256  # block.timestamp of the last time a report occured
    totalDebt: uint256  # Total outstanding debt that Strategy has
    totalGain: uint256  # Total returns that Strategy has realized for Vault
    totalLoss: uint256  # Total losses that Strategy has realized for Vault

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256


event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Deposit:
    recipient: indexed(address)
    shares: uint256
    amount: uint256

event Withdraw:
    recipient: indexed(address)
    shares: uint256
    amount: uint256

event Sweep:
    token: indexed(address)
    amount: uint256

event LockedProfitDegradationUpdated:
    value: uint256

event StrategyAdded:
    strategy: indexed(address)
    debtRatio: uint256  # Maximum borrow amount (in BPS of total assets)
    minDebtPerHarvest: uint256  # Lower limit on the increase of debt since last harvest
    maxDebtPerHarvest: uint256  # Upper limit on the increase of debt since last harvest
    performanceFee: uint256  # Strategist's fee (basis points)


event StrategyReported:
    strategy: indexed(address)
    gain: uint256
    loss: uint256
    debtPaid: uint256
    totalGain: uint256
    totalLoss: uint256
    totalDebt: uint256
    debtAdded: uint256
    debtRatio: uint256

event FeeReport:
    management_fee: uint256
    performance_fee: uint256
    strategist_fee: uint256
    duration: uint256

event WithdrawFromStrategy:
    strategy: indexed(address)
    totalDebt: uint256
    loss: uint256

event UpdateGovernance:
    governance: address # New active governance


event UpdateManagement:
    management: address # New active manager

event UpdateRewards:
    rewards: address # New active rewards recipient


event UpdateDepositLimit:
    depositLimit: uint256 # New active deposit limit


event UpdatePerformanceFee:
    performanceFee: uint256 # New active performance fee


event UpdateManagementFee:
    managementFee: uint256 # New active management fee


event UpdateGuardian:
    guardian: address # Address of the active guardian


event EmergencyShutdown:
    active: bool # New emergency shutdown state (if false, normal operation enabled)


event UpdateWithdrawalQueue:
    queue: address[MAXIMUM_STRATEGIES] # New active withdrawal queue


event StrategyUpdateDebtRatio:
    strategy: indexed(address) # Address of the strategy for the debt ratio adjustment
    debtRatio: uint256 # The new debt limit for the strategy (in BPS of total assets)


event StrategyUpdateMinDebtPerHarvest:
    strategy: indexed(address) # Address of the strategy for the rate limit adjustment
    minDebtPerHarvest: uint256  # Lower limit on the increase of debt since last harvest


event StrategyUpdateMaxDebtPerHarvest:
    strategy: indexed(address) # Address of the strategy for the rate limit adjustment
    maxDebtPerHarvest: uint256  # Upper limit on the increase of debt since last harvest


event StrategyUpdatePerformanceFee:
    strategy: indexed(address) # Address of the strategy for the performance fee adjustment
    performanceFee: uint256 # The new performance fee for the strategy


event StrategyMigrated:
    oldVersion: indexed(address) # Old version of the strategy to be migrated
    newVersion: indexed(address) # New version of the strategy


event StrategyRevoked:
    strategy: indexed(address) # Address of the strategy that is revoked


event StrategyRemovedFromQueue:
    strategy: indexed(address) # Address of the strategy that is removed from the withdrawal queue


event StrategyAddedToQueue:
    strategy: indexed(address) # Address of the strategy that is added to the withdrawal queue

event NewPendingGovernance:
    pendingGovernance: indexed(address)

# NOTE: Track the total for overhead targeting purposes
strategies: public(HashMap[address, StrategyParams])
MAXIMUM_STRATEGIES: constant(uint256) = 20
DEGRADATION_COEFFICIENT: constant(uint256) = 10 ** 18

# Ordering that `withdraw` uses to determine which strategies to pull funds from
# NOTE: Does *NOT* have to match the ordering of all the current strategies that
#       exist, but it is recommended that it does or else withdrawal depth is
#       limited to only those inside the queue.
# NOTE: Ordering is determined by governance, and should be balanced according
#       to risk, slippage, and/or volatility. Can also be ordered to increase the
#       withdrawal speed of a particular Strategy.

# NOTE: Track the total for overhead targeting purposes
withdrawalQueue: public(address[MAXIMUM_STRATEGIES])

emergencyShutdown: public(bool)

depositLimit: public(uint256)  # Limit for totalAssets the Vault can hold
debtRatio: public(uint256)  # Debt ratio for the Vault across all strategies (in BPS, <= 10k)
totalIdle: public(uint256)
totalDebt: public(uint256)
lastReport: public(uint256)
activation: public(uint256) # block.timestamp of contract deployment
lockedProfit: public(uint256) # how much profit is locked and can't be withdrawn
lockedProfitDegradation: public(uint256) # rate per block of degradation. DEGRADATION_COEFFICIENT is 100% per block
rewards: public(address) # Rewards contract where Governance fees are sent to
# Governance Fee for management of Vault (given to `rewards`)
managementFee: public(uint256)
# Governance Fee for performance of Vault (given to `rewards`)
performanceFee: public(uint256)

# NOTE: I dont understand why these are here, but they are in the DeFi Vault and Needs to be updated based on ERC-7540
MAX_BPS: constant(uint256) = 10_000  # 100%, or 10k basis points, NOTE: Why is it calculate this way?
# NOTE: A four-century period will be missing 3 of its 100 Julian leap years, leaving 97.
#       So the average year has 365 + 97/400 = 365.2425 days
#       ERROR(Julian): -0.0078
#       ERROR(Gregorian): -0.0003
#       A day = 24 * 60 * 60 sec = 86400 sec
#       365.2425 * 86400 = 31556952.0
SECS_PER_YEAR: constant(uint256) = 31_556_952  # 365.2425 days
# `nonces` track `permit` approvals with signature.
nonces: public(HashMap[address, uint256])
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")


@external
def initialize(
    token: address, # the token that is being deposited into the vault and withdrawn from the vault
    governance: address, # the address that is governing the vault
    management: address, # the address that is managing the vault
    nameOverride: String[64], # the name of the vault
    symbolOverride: String[32], # the symbol of the vault
    guardian: address = msg.sender, # the address that is the guardian of the vault
    management: address = msg.sender, # the address that is the management of the vault
    rewards: address, # the address that is the rewards of the vault
):
    """
    @notice
        Initializes the Vault, this is called only once, when the contract is
        deployed.
        The performance fee is set to 10% of yield, per Strategy.
        The management fee is set to 2%, per year.
        The initial deposit limit is set to 0 (deposits disabled); it must be
        updated after initialization.
    @dev
        If `nameOverride` is not specified, the name will be 'nv'
        combined with the name of `token`.

        If `symbolOverride` is not specified, the symbol will be 'nv'
        combined with the symbol of `token`.

        The token used by the vault should not change balances outside transfers and 
        it must transfer the exact amount requested. Fee on transfer and rebasing are not supported.
    @param token The token that may be deposited into this Vault.
    @param governance The address authorized for governance interactions.
    @param management The address of the vault manager.
    @param nameOverride Specify a custom Vault name. Leave empty for default choice.
    @param symbolOverride Specify a custom Vault symbol name. Leave empty for default choice.
    @param guardian The address authorized for guardian interactions. Defaults to caller.
    """
    assert self.activation == 0  # dev: no devops199 this is for? why is this here?
    if nameOverride == "":
        self.name = concat(DetailedERC20(token).symbol(), " nVault")
    else:
        self.name = nameOverride
    if symbolOverride == "":
        self.symbol = concat("nv", DetailedERC20(token).symbol())
    else:
        self.symbol = symbolOverride
    decimals: uint256 = DetailedERC20(token).decimals() # this is the decimals of the token
    self.decimals = decimals
    assert decimals < 256 # dev: see VVE-2020-0001? why is this here?
    self.governance = governance
    log UpdateGovernance(governance)
    self.management = management
    log UpdateManagement(management)
    self.rewards = rewards
    log UpdateRewards(rewards)
    self.guardian = guardian
    log UpdateGuardian(guardian)
    self.performanceFee = 1000  # 10% of yield (per Strategy)
    log UpdatePerformanceFee(convert(1000, uint256))
    self.managementFee = 200  # 2% per year
    log UpdateManagementFee(convert(200, uint256))
    self.lastReport = block.timestamp
    self.activation = block.timestamp
    self.lockedProfitDegradation = convert(DEGRADATION_COEFFICIENT * 46 / 10 ** 6 , uint256) # 6 hours in blocks, why degradation coefficient?
    # EIP-712

@pure
@external
def apiVersion() -> String[28]:
    """
    @notice
        Used to track the deployed version of this contract. In practice you
        can use this version number to compare with Napfi's GitHub and
        determine which version of the source matches this deployed contract.
    @dev
        All strategies must have an `apiVersion()` that matches the Vault's
        `API_VERSION`.
    @return API_VERSION which holds the current version of this contract.
    """
    return API_VERSION

"""
    @notice domain_seperator is a unique fingerprint of teh contract + network + version
    it will unsures that a signature is only valid under:
    - This contract(self)
    - On this chain(chain.id)
    - With this API version(API_VERSION)
    - With this name("Napfi Vault)

"""
@view
@internal
def domain_seperator() -> bytes32: # this is the domain seperator for the EIP-712
    return keccak256(
        concat(
            DOMAIN_TYPE_HASH, 
            keccak256(convert("Napfi Vault", Bytes[11])), # name
            keccak256(convert(API_VERSION, Bytes[28])), # api version
            convert(chain.id, bytes32), # chain Id
            convert(self, bytes32) # self contract
        )
    )

@view
@external
def DOMAIN_SEPARATOR() -> bytes32:
    return self.domain_seperator()
    
@external
def setName(name: String[64]):
    """
    @notice
        Used to change the value of `name`.

        This may only be called by governance.
    @param name the new name to use.
    """
    assert msg.sender == self.governance
    self.name = name

@external
def setSymbol(symbol: String[64]):
    """
    @notice
        Used to change the value of `symbol`.

        This may be only called by governance.
    @param symbol The new symbol to use.
    """

    assert.msg.sender == self.governance
    self.symbol = symbol

# 2-phase commit for a change in governance
@external
def setGovernance(governance: address):
    """
    @notice
        Nominate a new address to use as governance.

        The change does not go into effect immediately. This function sets a
        pending change, and the governance address is not updated until
        the proposed governance address has accepted the responsibility.

        This may only be called by the current governance address.
    @param governance The address requested to take over Vault governance.
    """
    assert msg.sender == self.governance
    log NewPendingGovernance(governance)
    self.pendingGovernance = governance # accept governance address as pendingGovernance

#  after pendingGovernance we need to accept governance
@external
def acceptGovernance():
    """
    @notice
        Once a new governance address has been proposed using setGovernance(),
        this function may be called by the proposed address to accept the
        responsibility of taking over governance for this contract.

        This may only be called by the proposed governance address.
    @dev
        setGovernance() should be called by the existing governance address,
        prior to calling this function.
    """
    assert.msg.sender == self.pendingGovernance
    self.governance = msg.sender
    log UpdateGovernance(msg.sender) # accept governance new address

@external
def setManagement(management: address):
    """
    @notice
        Changes the management address.
        Management is able to make some investment decisions adjusting parameters.

        This may only be called by governance.
    @param management The address to use for managing.
    """
    assert.msg.sender == self.governance
    self.management = management
    log UpdateManagement(management)

@external
def setRewards(rewards: address):
    """
    @notice
        Changes the rewards address. Any distributed rewards
        will cease flowing to the old address and begin flowing
        to this address once the change is in effect.

        This will not change any Strategy reports in progress, only
        new reports made after this change goes into effect.

        This may only be called by governance.
    @param rewards The address to use for collecting rewards.
    """
    assert msg.sender == self.governance
    assert not (rewards in [self, ZERO_ADDRESS])
    self.rewards = rewards
    log UpdateRewards(rewards)

@external 
def setLockedProfitDegradation(degradation: uint256):
    """
    @notice
        Changes the locked profit degradation.
    @param degradation The rate of degradation in percent per second scaled to 1e18.
    """
    assert msg.sender == self.governance
    # Since "degradation" is of type uint256 it can never be less than zero
    assert degradation <= DEGRADATION_COEFFICIENT # How is it correlate?
    self.lockedProfitDegradation = degradation
    log LockedProfitDegradationUpdated(degradation) 

@external
def setDepositLimit(limmit: uint256):
    """
    @notice
        Changes the maximum amount of tokens that can be deposited in this Vault.

        Note, this is not how much may be deposited by a single depositor,
        but the maximum amount that may be deposited across all depositors.

        This may only be called by governance.
    @param limit The new deposit limit to use.
    """
    assert msg.sender == self.governance
    self.depositLimit = limit
    log UpdateDepositLimit(limit) # what does UpdateDepositLimit do? and why it's needed?


@external
def setPerformanceFee(fee: uint256):
    """
    @notice
        Used to change the value of `performanceFee`.

        Should set this value below the maximum strategist performance fee.

        MAX_BPS is 10,000 so this means that the maximum performance fee is 50%
        of the yield that the strategy generates, that is why it is devided by 2.

        and the mapping is:

        - 50% for governance/treasury
        - 50% for strategist
        ---------------
        100% of the performance fee
        ---------------
        10% of the yield generated by the strategy
        5% for governance/treasury
        5% for strategist
        ---------------
        100% of the yield generated by the strategy
        ---------------

        This may only be called by governance.
    @param fee The new performance fee to use.
    """
    assert msg.sender == self.governance
    assert fee <= MAX_BPS / 2 # 10,000 / 2 = 5,000 = 50%
    self.performanceFee = fee
    log UpdatePerformanceFee(fee)
    
@external
def setManagementFee(fee: uint256):
    """
    @notice
        Used to change the value of `managementFee`.

        This may only be called by governance.
    @param fee The new management fee to use.
    """
    assert msg.sender == self.governance
    assert fee <= MAX_BPS # 100% goes to governance/treasury
    self.managementFee = fee
    log UpdateManagementFee(fee)

@external
def setGuardian(guardian: address):
    """
    @notice
        Used to change the address of `guardian`.

        This may only be called by governance or the existing guardian.
    @param guardian The new guardian address to use.
    """

    # How can we manage it? both from guardian and governance itself? 50% 50%?
    assert msg.sender in [self.guardian, self.governance] # Trusted current guradian and ggovernance, double security vault design
    self.guardian = guardian
    log UpdateGuardian(guardian)

@external
def setEmergencyShutdown(active: bool):
    """
    @notice
        Activates or deactivates Vault mode where all Strategies go into full
        withdrawal.

        During Emergency Shutdown:
        1. No Users may deposit into the Vault (but may withdraw as usual.)
        2. Governance may not add new Strategies.
        3. Each Strategy must pay back their debt as quickly as reasonable to
            minimally affect their position.
        4. Only Governance may undo Emergency Shutdown.

        See contract level note for further details.

        This may only be called by governance or the guardian.
    @param active
        If true, the Vault goes into Emergency Shutdown. If false, the Vault
        goes back into Normal Operation.
    """
    if active:
        assert msg.sender in [self.governance, self.guardian] # Emergency can be treggered by guardian or governance
        assert msg.sender == self.governance # but only governance can disable emergency shutdown
    self.emergencyShutdown = active
    log EmergencyShutdown(active)


@external
def setWithdrawalQueue(queue: address[MAXIMUM_STRATEGIES]):
    """
    @notice
        Updates the withdrawalQueue to match the addresses and order specified
        by `queue`.

        There can be fewer strategies than the maximum, as well as fewer than
        the total number of strategies active in the vault. `withdrawalQueue`
        will be updated in a gas-efficient manner, assuming the input is well-
        ordered with 0x0 only at the end.

        This may only be called by governance or management.
    @dev
        This is order sensitive, specify the addresses in the order in which
        funds should be withdrawn (so `queue`[0] is the first Strategy withdrawn
        from, `queue`[1] is the second, etc.)

        This means that the least impactful Strategy (the Strategy that will have
        its core positions impacted the least by having funds removed) should be
        at `queue`[0], then the next least impactful at `queue`[1], and so on.
    @param queue
        The array of addresses to use as the new withdrawal queue. This is
        order sensitive.
    """
    assert msg.sender in [self.governance, self.management]

    # HACK: Temporary until Vyper adds support for Dynamic arrays
    old_queue: address[MAXIMUM_STRATEGIES] = empty(address[MAXIMUM_STRATEGIES]) # empty address array of max stratergies is for old queue
    for i in range(MAXIMUM_STRATEGIES):
        old_queue[i] = self.withdrawalQueue[i]

        # checks to make sure that the old queue and new queue are same ZERO_ADDRESS in slot i index
        if queue[i] == ZERO_ADDRESS:
            # NOTE: Cannot use this method to remove entries from the queue
            assert old_queue[i] == ZERO_ADDRESS # to make sure that old queue and new queue are same ZERO_ADDRESS in i 
            break
        # NOTE: Ensure that the strategy is active and not duplicated nor increase nor decrease the size of the queue
        # NOTE: This will also ensure that the strategy exists in the old queue and not accidently remove any strategy from the queue
        # queue[i] = old_queue[i] != zero_address
        assert old_queue[i] != ZERO_ADDRESS 

        # NOTE: Check that the strategy is active by block.timestamp and not duplicated in the new queue
        # so block.timestamp > 0 means that the strategy is active
        assert self.strategies[queue[i]].activation > 0 # to make sure that the strategy is active and not duplicated 

        # ------------------------------------------------------------------
        existsInOldQueue: bool = False

        # NOTE: Check that the strategy is not duplicated in the new queue
        # old_queue[j] = queue[i] != zero_address
        for j in range(MAXIMUM_STRATEGIES):
            if old_queue[j] == queue[i]:
                existsInOldQueue = True
                break
            if old_queue[j] == ZERO_ADDRESS:
                existsInOldQueue = True
                break

            if j <= i:
                # NOTE: This will only check for duplicate entries up to i because the rest of the entries are not relevant
                continue
            assert old_queue[j] != queue[i] # to make sure that the strategy is not duplicated in the new queue

        assert existsInOldQueue # to make sure that the strategy exists in the old queue

        self.withdrawalQueue[i] = queue[i] # set the new queue
    log UpdateWithdrawalQueue(queue)

@internal
def erc20_safe_transfer(token: address. receiver, address, amount: uint256):
    """
    @notice
        Helper function to safely transfer ERC20 tokens.
    @dev
        Some ERC20 tokens do not return a boolean value on transfer,
        so we need to check the return value and ensure that it is
        either empty or true.
    @param token The address of the ERC20 token.
    @param receiver The address to send the tokens to.
    @param amount The amount of tokens to send.
    """
    response: Bytes[32] = raw_call( # using raw_call to call the transfer function of the ERC20 token
        token,
        concat( # method id of transfer function + receiver address + amount
            method_id("transfer(address,uint256)"),
            convert(receiver, bytes32),
            convert(amount, bytes32)
        ),
        max_outsize=32 # max outsize is 32 bytes (the size of a uint256 or bool
    )
    if len(response) > 0: # if the response is not empty
        assert convert(response, bool), "Transfer failed!" # to make sure that the transfer was successful
    

@internal
def erc20_safe_transferFrom(token: address, sender: address, receiver: address, amount: uint256):
    """
    @notice
        Helper function to safely transferFrom ERC20 tokens.
    @dev
        Some ERC20 tokens do not return a boolean value on transferFrom,
        so we need to check the return value and ensure that it is
        either empty or true.
    @param token The address of the ERC20 token.
    @param sender The address to send the tokens from.
    @param receiver The address to send the tokens to.
    @param amount The amount of tokens to send.
    """
    response: Bytes[32] = raw_call( # using raw_call to call the transfer
        token,
        concat( # method id of transferFrom function + sender address + receiver address + amount
            method_id("transferFrom(address,address,uint256)"),
            convert(sender, bytes32),
            convert(receiver, bytes32),
            convert(amount, bytes32)
        ),
        max_outsize=32 # max outsize is 32 bytes (the size of a uint256 or bool
    )
    if len(response) > 0: # if the response is not empty
        assert convert(response, bool), "TransferFrom failed!" # to make sure that the transfer


@internal
def _transfer(sender: address, receiver: address, amount: uint256):
    """
    @notice
        Internal function to transfer shares from one address to another.
    @param sender The address to send the shares from.
    @param receiver The address to send the shares to.
    @param amount The amount of shares to send.
    """
    assert receiver != ZERO_ADDRESS, "Transfer to zero address" # dev: transfer to zero address
    assert self.balanceOf[sender] >= amount, "Insufficient balance" # dev: insufficient balance
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount
    log Transfer(sender, receiver, amount) # emit transfer event


@external
def transfer(receiver: address, amount: uint256) -> bool:
    """
    @notice
        Transfer shares from the caller's address to another address.
    @param receiver The address to send the shares to.
    @param amount The amount of shares to send.
    @return True if the transfer was successful.
    """
    self._transfer(msg.sender, receiver, amount)
    return True
    

@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    """
    @notice
        Transfers `amount` shares from `sender` to `receiver`. This operation will
        always return true, unless the user is attempting to transfer shares
        to this contract's address, or to 0x0.

        Unless the caller has given this contract unlimited approval,
        transfering shares will decrement the caller's `allowance` by `amount`.
    @param sender The address shares are being transferred from.
    @param receiver
        The address shares are being transferred to. Must not be this contract's
        address, must not be 0x0.
    @param amount The quantity of shares to transfer.
    @return True if the transfer was successful.
    """

    # Unlimited approval (saves an SSTORAGE write)
    if self.allowance[sender][msg.sender] != MAX_UINT256:
        allowance: uint256 = self.allowance[sender][msg.sender] - amount
        self.allowance[sender][msg.sender] = allowance
        assert allowance <= self.allowance[sender][msg.sender], "Transfer exceeds allowance" #
        # NOTE: Cannot overflow because we check that the allowance is >= amount        
        log Approval(sender, msg.sender, allowance)
    self._transfer(sender, receiver, amount)
    return True


@external
def increaseAllowance(spender: address, allowance: uint256):
    self.allowance[msg.sender][spender] += allowance
    assert self.allowance[msg.sender][spender] >= allowance, "Allowance overflow" # dev: allowance overflow
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True


@external
def decreaseAllowance(spender: address, allowance: uint256):
    self.allowance[msg.sender][spender] -= allowance
    assert self.allowance[msg.sender][spender] <= allowance, "Allowance underflow" # dev: allowance underflow
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True

@external
def permit(owner: address, spender: address, value: uint256, deadline: uint256, v: uint8, r: bytes32, s: bytes32):
    """
    @notice
        Approves spender by owner's signature to expend owner's tokens.
        See https://eips.ethereum.org/EIPS/eip-2612.

    @param owner The address which is a source of funds and has signed the Permit.
    @param spender The address which is allowed to spend the funds.
    @param amount The amount of tokens to be spent.
    @param expiry The timestamp after which the Permit is no longer valid.
    @param signature A valid secp256k1 signature of Permit by owner encoded as r, s, v.
    @return True, if transaction completes successfully
    """
    assert owner != ZERO_ADDRESS, "Owner cannot be zero address" # dev: owner cannot be zero address
    assert spender != ZERO_ADDRESS, "Spender cannot be zero address" # dev: spender
    assert expiery >= block.timestamp, "Permit expired" # dev: permit expired

    nonce:uint256 = self.nonces[owner]
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            self.domain_seperator(),
            keccak256(
                concat(
                    PERMIT_TYPE_HASH,
                    convert(owner, bytes32),
                    convert(spender, bytes32),
                    convert(amount, bytes32),
                    convert(nonce, bytes32),
                    convert(expiry, bytes32)
                )
            )
        )
    )

    # NOTE: signature is packed as r, s, v: offchain signing for owner, but spender still spend gas
    # @dev: how does it work under the hood? 
    # [r ............ 32 bytes][s ............ 32 bytes][v .. 1 byte]
    #   0x
    #71c3...1a (32 bytes for r)
`   #9f72...e3 (32 bytes for s)
      #1b        (1 byte for v = 27)

    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)

    # NOTE: ecrecover is built-in function that returns the address that signed a hashed message (digest) with signature (v, r, s)
    assert ecrecover(digest, v, r, s) == owner, "Invalid signature" # dev: invalid signature
    self.allowance[owner][spender] = amount
    # prevent double spend of signature by incrementing the nonce
    self.nonces[owner] = nonce + 1
    log Approval(owner, spender, amount)
    return True


@view
@internal
def _totalAssets() -> uint256:
    """
    @notice
        Internal view function to calculate the total assets of the vault.
        This includes the total idle assets, the total debt across all strategies,      
        and the total estimated assets across all strategies.
    @return The total assets of the vault.
    """
    return self.totalIdle + self.totalDebt #+ self._estimatedTotalAssets() # NOTE: Why is estimatedTotalAssets() commented out?

@view
@external
def totalAssets() -> uint256:
    """
    @notice
        Returns the total quantity of all assets under control of this
        Vault, whether they're loaned out to a Strategy, or currently held in
        the Vault.
    @return The total assets under control of this Vault.
    """
    return self._totalAssets()

@view
@internal
def _calculateLockedProfit() -> uint256:
    """"
    @notice
        Internal view function to calculate the locked profit of the vault.
        This is used to determine how much profit is currently locked and cannot be withdrawn.
        The locked profit degrades over time, so the longer it has been since
        the last report, the less profit is locked.
    @ return The amount of profit that is currently locked and cannot be withdrawn.
    @ fun fact: altoughh thhe funds is always can be withdrawn, the profit is locked and cannot be withdrawn
    because it is not yet realized profit/working profit, so it is locked until the next report.
    This prevents flash-depositors from withdrawing profit that has not yet been realized.
    """
    # NOTE: This function calculates the amount of profit that is currently locked and cannot be withdrawn.
    # lockedFundsRatio R = (t-t0) * degradation
    # degradation = DERADATION_COEFFICIENT / (6 hours in blocks)
    lockedFundsRatio: uint256 = (block.timestamp - self.lastReport) * self.lockedProfitDegradation

    # LockedProfit = LockedProfit - (LockedFundsRatio * lockedProfit)
    if(lockedFundsRatio < DEGRADATION_COEFFICIENT):
        lockedProfit: uint256 = self.lockedProfit
        return lockedProfit - (
            lockedFundsRatio 
            * lockedProfit 
            / DEGRADATION_COEFFICIENT
        )
    else: 
        return 0

@view
@external
def _freeFunds() -> uint256:
    """"
    @notice
        Internal view function to calculate the free funds of the vault.
        This is used to determine how much funds are currently available for withdrawal.
        The free funds is the total assets minus the locked profit.
    @ return The amount of funds that is currently available for withdrawal.
    """
    return self._totalAssets() - self._calculateLockedProfit()
        
@internal
def _issueSharesForAmount(to: address, amount: uint256) -> uint256:
    """
    @notice
        Internal function to issue shares to an address for a given amount of assets.
        The number of shares issued is based on the current total assets and total supply.
    @param to The address to issue the shares to.
    @param amount The amount of assets being deposited.
    @return The number of shares issued.
    """
    shares: uint256 = 0
    totalSupply: uint256 = self.totalSupply
    if totalSupply > 0:
        shares = amount * totalSupply / self._totalAssets()
    else:
        shares = amount
    assert shares != 0, "Zero shares" # dev: zero shares

    # Mint new shares
    self.totalSupply = totalSupply + shares
    self.balanceOf[to] += shares
    log Transfer(ZERO_ADDRESS, to, shares) # emit transfer event from zero address to

    return shares




    
    




    



    


    

    

    


    



