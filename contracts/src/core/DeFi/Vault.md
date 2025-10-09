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
# NOTE: Artist address, can be a multisig wallet
artist: public(address)
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
    artist_fees: uint256 # fees sent to the artist
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

event UpdateArtist:
    artist: address # Address of the active artist

event UpdateArtistFee:
    artistFee: uint256


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
    artistNameOverride: String[64], # the name of the Artist
    artistSymbolOverride: String[32], # the symbol of the artist
    guardian: address = msg.sender, # the address that is the guardian of the vault
    management: address = msg.sender, # the address that is the management of the vault
    artist: address = msg.sender, # the address that is the artist of the vault
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
    if artistNameOverride == "":
        self.name = concat(DetailedERC20(token).symbol(), " nArtist")
    else:
        self.name = artistNameOverride
    if artistSymbolOverride = "":
        self.symbol = concat("nV", DetailedERC20(token).symbol())
    decimals: uint256 = DetailedERC20(token).decimals() # this is the decimals of the token
    self.decimals = decimals
    assert decimals < 256 # dev: see VVE-2020-0001? why is this here?
    self.artist = artist # Log artist
    log UpdateArtist(artist)
    self.governance = governance
    log UpdateGovernance(governance)
    self.management = management
    log UpdateManagement(management)
    self.rewards = rewards
    log UpdateRewards(rewards)
    self.guardian = guardian
    log UpdateGuardian(guardian)
    self.artist = artist
    log UpdateArtist(artist)
    self.artistFee = 10  # 10% from their audience/fans affiliate deposit to vault
    log UpdateArtistFee(convert(10, uint256))
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

# NOTE: set Name and Symbol for Vault tokens
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

# NOTE: set Name and Symbol for Artist
@external
def setArtistName(name: String[64]):
    """
    @notice
        Used to change the value of `name`.

        This may only be called by governance.
    @param name the new name to use.
    """
    assert msg.sender == self.artist
    self.name = name

@external
def setArtistSymbol(symbol: String[64]):
    """
    @notice
        Used to change the value of `symbol`.

        This may be only called by governance.
    @param symbol The new symbol to use.
    """

    assert.msg.sender in [self.artist, self.governance]
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
        2.5% for strategist
        2.5% for artist fee for artist are based from tokenized vault and not in main vault, this desin is to prevent free-rider artist to get reward that tehy dont have
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


@external
@nonreentrant("withdraw")
def deposit(_amount: uint256 = MAX_UINT256, recipient: address = msg.sender) -> uint256:
    """
    @notice
        Deposits `_amount` `token`, issuing shares to `recipient`. If the
        Vault is in Emergency Shutdown, deposits will not be accepted and this
        call will fail.
    @dev
        Measuring quantity of shares to issues is based on the total
        outstanding debt that this contract has ("expected value") instead
        of the total balance sheet it has ("estimated value") has important
        security considerations, and is done intentionally. If this value were
        measured against external systems, it could be purposely manipulated by
        an attacker to withdraw more assets than they otherwise should be able
        to claim by redeeming their shares.

        On deposit, this means that shares are issued against the total amount
        that the deposited capital can be given in service of the debt that
        Strategies assume. If that number were to be lower than the "expected
        value" at some future point, depositing shares via this method could
        entitle the depositor to *less* than the deposited value once the
        "realized value" is updated from further reports by the Strategies
        to the Vaults.

        Care should be taken by integrators to account for this discrepancy,
        by using the view-only methods of this contract (both off-chain and
        on-chain) to determine if depositing into the Vault is a "good idea".
    @param _amount The quantity of tokens to deposit, defaults to all.
    @param recipient
        The address to issue the shares in this Vault to. Defaults to the
        caller's address.
    @return The issued Vault shares.
    """
    assert not self.emergencyShutdown, "Deposits disabled during emergency" # dev: deposits disabled during emergency
    assert recipient not in [self, ZERO_ADDRESS], "Invalid recipient" # dev: invalid recipient

    amount: uint256 = _amount

    # If _amount not specified, transfer the full token balance,
    # up to deposit limit
    if amount == MAX_UINT256:
        amount = min(
            self.depositLimit - self._totalAssets(), # deposit limit - total assets = max amount that can be deposited
            self.token.balanceOf(msg.sender) # balance of the caller
        )
    else:
        # ensure that the deposit does not exceed the deposit limit
        assert self._totalAssets() + amount <= self.depositLimit, "Deposit exceeds limit"

    # ensure deposit > 0
    assert amount > 0, "Zero deposit" # dev: zero deposit

    # Issue new shares (needs to be done before taking deposit to be accurate)
    # Shares are issued to recipient (may be different from msg.sender)
    # See @dev note, above.
    shares: uint256 = self._issueSharesForAmount(recipient, amount)

    # Tokens are transferred from msg.sender (may be different from _recipient)
    self.erc20_safe_transferFrom(self.token.address, msg.sender, self, amount)
    # NOTE: totalIdle is the total amount of tokens that are not invested in any strategy
    # amount is the new amount that is being deposited and not yet invested in any strategy
    self.totalIdle += amount

    log Deposit(recipient, shares, amount) # emit deposit event

    return shares # Just in case someone wants them
    
@view
@internal
def _shareValue(shares: uint256) -> uint256:
    # Returns price = 1:1 if vault is empty
    if self.totalSupply == 0:
        return shares

    # Determines the current value of `shares`.
    # NOTE: if sqrt(Vault.totalAssets()) >>> 1e39, this could potentially revert

    """
    @notice

    Purpose: Converts shares → token amount.
    1. You already own some shares in the vault.
    2. You want to know how much your shares are worth in underlying tokens right now.
    3. Uses _freeFunds() because locked profits shouldn’t be redeemable yet.

    There are two "vaults" in this system:
    1. Unlocked vault (freeFunds)
        This is the "real vault" users can interact with right now.
        It contains all deposits + old profits + whatever part of new profits has already unlocked.

    2. Locked vault (lockedProfit)
        This is like a separate shadow vault that nobody can touch yet.
        It holds the newly reported profits for a short time.
        Over the unlock period, its contents "leak" into the unlocked vault.

    Total assets = unlocked vault + locked vault
                  = freeFunds + lockedProfit

    This way, we can ensure that:
    1. The share price never decreases (because totalAssets only goes up).
    2. New profits are gradually released over time, so that flash depositors cannot take
       advantage of a sudden increase in share price.
    3. It prevents people from gaming the system by timing deposits and withdrawals
       around reports, sandwiching the report transaction.
    """
    return (
        shares
        * self._freeFunds()
        / self.totalSupply
    )


@view
@internal
def _sharesForAmount(amount: uint256) -> uint256:
        """
        @notice
            Internal view function to calculate the number of shares for a given amount of assets.
        @param amount The amount of assets to convert to shares.
        @return The number of shares that would be issued for the given amount of assets.
        """
        # Determines the quantity of shares to issue for a given deposit.
        # NOTE: if sqrt(Vault.totalAssets()) >>> 1e39, this could potentially revert

    _freeFunds: uint256 = self._freeFunds()
    if _freeFunds > 0:
        # NOTE: if sqrt(token.totalSupply()) > 1e37, this could potentially revert
        return (
            amount
            * self.totalSupply
            / _freeFunds
        )
    else:
        return 0
    

@view
@external
def maxAvailableShares() -> uint256:
    """
    @notice
        Determines the maximum quantity of shares this Vault can facilitate a
        withdrawal for, factoring in assets currently residing in the Vault,
        as well as those deployed to strategies on the Vault's balance sheet.
    @dev
        Regarding how shares are calculated, see dev note on `deposit`.

        If you want to calculated the maximum a user could withdraw up to,
        you want to use this function.

        Note that the amount provided by this function is the theoretical
        maximum possible from withdrawing, the real amount depends on the
        realized losses incurred during withdrawal.
    @return The total quantity of shares this Vault can provide.
    """
    shares: uint256 = self._sharesForAmount(self.totalIdle)

    for strategy in self.withdrawalQueue:
        if strategy == ZERO_ADDRESS:
            break
        shares += self._sharesForAmount(self.strategies[strategy].totalDebt)

    return shares


@internal
    def _reportLoss(strategy: address, loss: uint256):
        # Loss is up to the total debt issued of the strategy
        totalDebt: uint256 = self.strategies[strategy].totalDebt
        # NOTE: totalDebt: Current allocated capital that te vault given to this strategy
        assert totalDebt >= loss, "Loss exceeds total debt" # dev: loss exceeds total debt

        # Also, make sure we reduce our trust with the strategy by the amount of loss
        if self.debtRatio != 0:
            # NOTE: The context to this calculation is different than the calculation in `_reportLoss`,
            # this calculation intentionally approximates via `totalDebt` to avoid manipulatable results
            ratio_change: uint256 = min(
                # NOTE: This calculation isn't 100% precise, the adjustment is ~10%-20% more severe due to EVM math
                loss * self.debtRatio / self.totalDebt,
                self.strategies[strategy].debtRatio,
            )
            # NOTE: This is update total debt ratio of the individual strategy trust
            self.strategies[strategy].debtRatio -= ratio_change
            # NOTE: This is update total debt ratio of the total debt accross all strategies trust
            self.debtRatio -= ratio_change
        # Finally, adjust our strategy's parameters by the loss
        # NOTE: totalLoss: Cumulative losses that the strategy has reported to the vault
        self.strategies[strategy].totalLoss += loss
        # NOTE: This is update total debt of the total debt accross all strategies
        self.strategies[strategy].totalDebt = totalDebt - loss
        # NOTE: This update total individual strategy debt
        self.totalDebt -= loss



@external
@nonreentrant("withdraw")
def withdraw(
    maxShares: uint256 = MAX_UINT256,
    recipient: address = msg.sender,
    maxLoss: uint256 = 1, # 0.01% [BPS], BPS is basis point so maxLoss is 0.01% of the total assets that can be lost during withdrawal
) -> uint256:
    """
    @notice
        Withdraws the calling account's tokens from this Vault, redeeming
        amount `_shares` for an appropriate amount of tokens.

        See note on `setWithdrawalQueue` for further details of withdrawal
        ordering and behavior.
    @dev
        Measuring the value of shares is based on the total outstanding debt
        that this contract has ("expected value") instead of the total balance
        sheet it has ("estimated value") has important security considerations,
        and is done intentionally. If this value were measured against external
        systems, it could be purposely manipulated by an attacker to withdraw
        more assets than they otherwise should be able to claim by redeeming
        their shares.

        On withdrawal, this means that shares are redeemed against the total
        amount that the deposited capital had "realized" since the point it
        was deposited, up until the point it was withdrawn. If that number
        were to be higher than the "expected value" at some future point,
        withdrawing shares via this method could entitle the depositor to
        *more* than the expected value once the "realized value" is updated
        from further reports by the Strategies to the Vaults.

        Under exceptional scenarios, this could cause earlier withdrawals to
        earn "more" of the underlying assets than Users might otherwise be
        entitled to, if the Vault's estimated value were otherwise measured
        through external means, accounting for whatever exceptional scenarios
        exist for the Vault (that aren't covered by the Vault's own design.)

        In the situation where a large withdrawal happens, it can empty the 
        vault balance and the strategies in the withdrawal queue. 
        Strategies not in the withdrawal queue will have to be harvested to 
        rebalance the funds and make the funds available again to withdraw.
    @param maxShares
        How many shares to try and redeem for tokens, defaults to all.
    @param recipient
        The address to issue the shares in this Vault to. Defaults to the
        caller's address.
    @param maxLoss
        The maximum acceptable loss to sustain on withdrawal. Defaults to 0.01%.
        If a loss is specified, up to that amount of shares may be burnt to cover losses on withdrawal.
    @return The quantity of tokens redeemed for `_shares`.

    Putting it together in a withdrawal flow

User requests value worth of tokens.

Vault first tries to pay from totalIdle.

If not enough, Vault forces withdrawals from strategies.

Update self.totalIdle with whatever was successfully pulled.

If enough was gathered → burn equivalent shares.

If losses > user’s tolerance (maxLoss) → revert to protect user.
    """
    shares: uint256 = maxShares

    assert maxLoss <= MAX_BPS, "maxLoss exceeds 100%" # dev: maxLoss exceeds 100%

    # If _shares not specified, withdraw full balance
    if shares == MAX_UINT256:
        shares = self.balanceOf[msg.sender]
    
    # Limit to the shares available
    assert shares <= self.balanceOf[msg.sender], "Insufficient shares" # dev: insufficient

    # Ensure we are witdrawing something
    assert shares > 0, "Zero shares" # dev: zero shares

    value: uint256 = self._shareValue(shares) # value in token amount
    # NOTE: make sure to use totalIdle if none then use strategies
    vault_balance: uint256 = self.totalIdle # make a copy of totalIdle to avoid multiple SLOADs

    # NOTE: This function is when user want to withdraw more than what is available in the vault balance
    if value > vault_balance:
        # Not enough tokens in the idle vault by shares representative, withdraw from strategies
        # NOTE: We withdraw from each strategy in the withdrawal queue,
        # until we've withdrawn enough to cover the full amount.
        # NOTE: This loop will break when either we've withdrawn enough,
        # or we've gone through the entire withdrawal queue.
        for strategy in self.withdrawalQueue:
            if strategy == ZERO_ADDRESS:
                break
            
            # NOTE: Try to withrawl from idle vault first then real strategy
            if value <= vault_balance:
                break # we've withdrawn enough of shares

            amountNeeded: uint256 = value - vault_balance # amount needed to withdraw from strategies

            # NOTE: Don't withdraw more than the debt so that Strategy can still
            #       continue to work based on the profits it has
            # NOTE: This means that user will lose out on any profits that each
            #       Strategy in the queue would return on next harvest, benefiting others
            amountNeeded min(amountNeeded, self.strategies[strategy].totalDebt)
            if amountNeeded == 0:
                continue  # Nothing to withdraw from this Strategy, try the next one

            # Force withdraw amount from each Strategy in the order set by governance
            preBalance: uint256 = self.token.balanceOf(self) # balance before withdraw
            loss: uint256 = Strategy(strategy).withdraw(amountNeeded) # withdraw from strategy
            withdrawn: uint256 = self.token.balanceOf(self) - preBalance # actual amount withdrawn
            vault_balance += withdrawn # update idle vault balance

            # NOTE: Withdrawer incurs any losses from liquidation
            if loss > 0:
                value -= loss
                totalLoss += loss
                self._reportLoss(strategy, loss)

            # Reduce the Strategy's debt by the amount withdrawn ("realized returns")
            # NOTE: This doesn't add to returns as it's not earned by "normal means"
            self.strategies[strategy].totalDebt -= withdrawn
            self.totalDebt -= withdrawn
            log StrategyWithdrawal(strategy, withdrawn, loss) # emit strategy withdrawal event

            # NOTE: If we didn't withdraw as much as we wanted to, we may need to
            #       try the next strategy in the queue to get the full amount.
            #       This could happen if the Strategy doesn't have enough liquidity
            #       to cover the full amount needed.
            
        self.totalIdle = vault_balance # update totalIdle to the new balance
            # NOTE: We have withdrawn everything possible out of the withdrawal queue
            #       but we still don't have enough to fully pay them back, so adjust
            #       to the total amount we've freed up through forced withdrawals
        if vault_balance >= value:
            # NOTE: Burn # of shares that corresponds to what Vault has on-hand,
     `  `   #       including the losses that were incurred above during withdrawals
            shares = self._sharesForAmount(value + totalLoss)

        # NOTE: This loss protection is put in place to revert if losses from
        #       withdrawing are more than what is considered acceptable.
        assert totalLoss <= (maxLoss * value) / MAX_BPS, "Loss exceeds maxLoss" # dev: loss exceeds maxLoss

    # Burn shares from sender (full value of what they asked for, including losses)
    self.totalSupply -= shares
    self.balanceOf[msg.sender] -= shares
    log Transfer(msg.sender, ZERO_ADDRESS, shares) # emit transfer event to zero address
    # NOTE: We don't need to check for underflow above because we checked that shares <= balanceOf[msg.sender] earlier

    self.totalIdle -= value # update totalIdle to reflect the withdrawal
    # Withdraw remaining balance to _recipient (may be different to msg.sender) (minus fee)
    self.erc20_safe_transfer(self.token.address, recipient, value)
    log Withdraw(msg.sender, recipient, shares, value) # emit withdraw event

    return value # return the amount of tokens withdrawn


@view
@external
def pricePerShare() -> uint256:
    """
    @notice Gives the price for a single Vault share.
    @dev See dev note on `withdraw`.
    @return The value of a single share.
    """
    return self._shareValue(10 ** self.decimals)


@internal
def _organizeWithdrawalQueue():
    # Reorganize `withdrawalQueue` based on premise that if there is an
    # empty value between two actual values, then the empty value should be
    # replaced by the later value.
    # NOTE: Relative ordering of non-zero values is maintained.
    offset: uint256 = 0
    for idx range(MAXIMUM_STRATEGIES):
        strategy: uint256 = self.withdrawalQueue[idx]
        if strategy == ZERO_ADDRESS:
            offset += 1 # how many values we need to shift left, always '<= idx'
        elif offset > 0:
            # Shift left by `offset` amount
            self.withdrawalQueue[idx - offset] = strategy
            self.withdrawalQueue[idx] = ZERO_ADDRESS


@external
def addStrategy(
    strategy: address,
    debtRatio: uint256,
    minDebtPerHarvest: uint256,
    maxDebtPerHarvest: uint256,
    performanceFee: uint256,
):
    """
    @notice
        Add a Strategy to the Vault.

        This may only be called by governance.
    @dev
        The Strategy will be appended to `withdrawalQueue`, call
        `setWithdrawalQueue` to change the order.
    @param strategy The address of the Strategy to add.
    @param debtRatio
        The share of the total assets in the `vault that the `strategy` has access to.
    @param minDebtPerHarvest
        Lower limit on the increase of debt since last harvest
    @param maxDebtPerHarvest
        Upper limit on the increase of debt since last harvest
    @param performanceFee
        The fee the strategist will receive based on this Vault's performance.
    """
    # Check if queue is full
    assert self.withdrawalQueue[MAXIMUM_STRATEGIES - 1] == ZERO_ADDRESS, "Withdrawal queue full" # dev: withdrawal queue full
    
    # Checking calling conditions
    assert not self.emergencyShutdown, "Vault in emergency shutdown" # dev: vault in emergency shutdown
    assert msg.sender == self.governance, "Only governance" # dev: only governance

    # Check strategy conditions
    assert strategy != ZERO_ADDRESS, "Strategy cannot be zero address" # dev: strategy cannot
    assert self.strategies[strategy].activation == 0, "Strategy already added" # dev: strategy already added
    assert self == Strategy(strategy).vault(), "Strategy not linked to this vault" # dev: strategy not linked to this vault
    assert self.token.address == Strategy(strategy).want(), "Strategy token mismatch" # dev: strategy token mismatch

    # Check strategy parameters
    assert self.debtRatio + debtRatio <= MAX_BPS, "Total debt ratio exceeds 100%" # dev: total debt ratio exceeds 100%
    assert minDebtPerHarvest <= maxDebtPerHarvest, "minDebtPerHarvest exceeds maxDebtPerHarvest" # dev: minDebtPerHarvest exceeds maxDebtPerHarvest
    assert performanceFee <= MAX_BPS/2 # dev: performanceFee exceeds 100%
    
    # Add strategy to approved strategies
    self.strategies[strategy] = StrategyParams({
        performanceFee: performanceFee,
        activation: block.timestamp,
        debtRatio: debtRatio,
        minDebtPerHarvest: minDebtPerHarvest,
        maxDebtPerHarvest: maxDebtPerHarvest,
        totalDebt: 0,
        totalGain: 0,
        totalLoss: 0,
        lastReport: block.timestamp
    })
    log StrategyAdded(strategy, debtRatio, minDebtPerHarvest, maxDebtPerHarvest, performanceFee) # emit strategy added event

    # Update total debt ratio
    self.debtRatio += debtRatio

    # Add strategy to the end of the withdrawal queue
    self.withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy
    self._organizeWithdrawalQueue() # organize the withdrawal queue to remove any gaps


@external
def updateStrategyDebtRatio(
    strategy: address, 
    debtRatio: uint256):
    """
    @notice
        Change the quantity of assets `strategy` may manage.

        This may be called by governance or management.
    @param strategy The Strategy to update.
    @param debtRatio The quantity of assets `strategy` may now manage.
    """
    assert msg.sender in [self.governance, self.management], "Only governance or management" # dev: only governance or management
    assert self.strategies[strategy].activation > 0
    assert Strategy(strategy_).emergencyExit() == False, "Strategy in emergency exit" # dev: strategy in emergency exit
    self.strategies[strategy].debtRatio = debtRatio # update debt ratio
    self debtRatio += debtRatio # update total debt ratio
    assert self.debtRatio <= MAX_BPS, "Total debt ratio exceeds 100%" # dev: total debt ratio exceeds 100%
    log StrategyUpdateDebtRatio(strategy, debtRatio) # emit strategy update debt ratio event


    
@external
def updateStrategyMinDebtPerHarvest(
    strategy: address,
    minDebtPerHarvest: uint256):
    """
    @notice
        Change the quantity assets per block this Vault may deposit to or
        withdraw from `strategy`.

        So it works like this:
        - If the strategy has less debt than minDebtPerHarvest, it can request
          to borrow up to minDebtPerHarvest during its next harvest.
        - If the strategy has more debt than minDebtPerHarvest, it can be forced
          to return down to minDebtPerHarvest during the next harvest.
        - If the strategy has debt equal to minDebtPerHarvest, it can neither
          borrow nor be forced to return debt during the next harvest.
        - As this runs per batch of funds, not indivisual user funds, it is
          possible that the strategy ends up with a debt slightly above or
          below minDebtPerHarvest, depending on the size of the harvest.
        - This environment is perfect to make DEX architecture to integrate.

        This may only be called by governance or management.
    @param strategy The Strategy to update.
    @param minDebtPerHarvest The quantity of assets per harvest this Vault
        may now deposit to or withdraw from `strategy`.
    """
    assert msg.sender in [self.governance, self.management], "Only governance or management" # dev: only governance or management
    assert self.strategies[strategy].activation > 0
    assert self.strategies[strategy].maxDebtPerHarvest >= minDebtPerHarvest, "minDebtPerHarvest exceeds maxDebtPerHarvest" # dev: minDebtPerHarvest exceeds maxDebtPerHarvest
    # NOTE: We allow debtRatio to be 0, which means the strategy is still
    #       active, but no new debt will be given to it during `harvest`.
    self.strategiest[strategy].minDebtPerHarvest = minDebtPerHarvest
    log StrategyUpdateMinDebtPerHarvest(strategy, minDebtPerHarvest) # emit strategy update min debt per harvest event


@external
def updateStrategyMaxDebtPerHarvest(
    strategy: address,
    maxDebtPerHarvest: uint256
):
    
    """
    @notice
        Change the quantity assets per block this Vault may deposit to or
        withdraw from `strategy`.

        This may only be called by governance or management.
    @param strategy The Strategy to update.
    @param maxDebtPerHarvest
        Upper limit on the increase of debt since last harvest

        minDebtPerHarvest <= debt <= maxDebtPerHarvest
    """
        assert msg.sender in [self.management, self.governance]
    assert self.strategies[strategy].activation > 0
    assert self.strategies[strategy].minDebtPerHarvest <= maxDebtPerHarvest
    self.strategies[strategy].maxDebtPerHarvest = maxDebtPerHarvest
    log StrategyUpdateMaxDebtPerHarvest(strategy, maxDebtPerHarvest)


@external
def updateStrategyPerformanceFee(
    strategy: address,
    performanceFee: uint256,
):
    """
    @notice
        Change the fee the strategist will receive based on this Vault's performance.

        This may only be called by governance.
    @param strategy The Strategy to update.
    @param performanceFee The fee the strategist will receive based on this Vault's performance.
    """
    assert msg.sender == self.governance, "Only governance" # dev: only governance
    assert self.strategies[strategy].activation > 0, "Strategy not active" # dev: strategy not active
    assert performanceFee <= MAX_BPS/2, "performanceFee exceeds 50%" # dev: performanceFee exceeds 50%
    self.strategies[strategy].performanceFee = performanceFee
    log StrategyUpdatePerformanceFee(strategy, performanceFee) # emit strategy update performance fee event


@internal
def _revokeStrategy(strategy: address):
    self.debtRatio -= self.strategies[strategy].debtRatio
    self.strategies[strategy].debtRatio = 0 # NOTE: We set debtRatio to 0, which means the strategy is still
    #       active, but no new debt will be given to it during `harvest`.
    log StrategyRevoked(strategy) # emit strategy revoked event


@external
def migrateStrategy(
    oldVersion: address,
    newVersion: address
):
    """
    @notice
        Migrates a Strategy, including all assets from `oldVersion` to
        `newVersion`.

        This may only be called by governance.
    @dev
        Strategy must successfully migrate all capital and positions to new
        Strategy, or else this will upset the balance of the Vault.

        The new Strategy should be "empty" e.g. have no prior commitments to
        this Vault, otherwise it could have issues.
    @param oldVersion The existing Strategy to migrate from.
    @param newVersion The new Strategy to migrate to.
    """
    assert msg.sender == self.governance, "Only governance" # dev: only governance
    assert oldVersion != ZERO_ADDRESS, "Old version cannot be zero address" # dev: old version cannot be zero address
    assert oldVersion != newVersion, "Cannot migrate to same version" # dev: cannot migrate to same version
    assert self.strategies[oldVersion].activation > 0, "Old version not active" # dev: old version not active
    assert self.strategies[newVersion].activation == 0, "New version already active" # dev: new version already

    strategy: StrategyParams = self.strategies[oldVersion] # make a copy of the old strategy params

    self._revokeStrategy(oldVersion) # revoke the old strategy
    # _recokeStrategy will lower the debt ratio
    self.debtRatio += strategy.debtRatio # add the debt ratio of the old strategy to the total debt ratio
    # Debt is migrated to new strategy
    self.strategies[oldVersion].otalDebt = 0

    self.strategies[newVersion] = StrategyParams({
        performanceFee: strategy.performanceFee,
        activation: strategy.lastReport, # NOTE: We use lastReport as activation time to prevent unfair advantage
        debtRatio: strategy.debtRatio,
        minDebtPerHarvest: strategy.minDebtPerHarvest,
        maxDebtPerHarvest: strategy.maxDebtPerHarvest,
        totalDebt: strategy.totalDebt,
        totalGain: 0,
        totalLoss: 0,
        lastReport: strategy.lastReport
    })

    Strategy(oldVersion).migrate(newVersion) # migrate the old strategy to the new strategy
    log StrategyMigrated(oldVersion, newVersion) # emit strategy migrated event

    for idx in range(MAXIMUM_STRATEGIES):
        if self.withdrawalQueue[idx] == oldVersion:
            self.withdrawalQueue[idx] = newVersion
            return # Don't need to reorganize the queue as we are replacing one with another new version    


@external
def revokeStrategy(strategy: address = msg.sender):
    """
    @notice
        Revoke a Strategy, setting its debt limit to 0 and preventing any
        future deposits.

        This function should only be used in the scenario where the Strategy is
        being retired but no migration of the positions are possible, or in the
        extreme scenario that the Strategy needs to be put into "Emergency Exit"
        mode in order for it to exit as quickly as possible. The latter scenario
        could be for any reason that is considered "critical" that the Strategy
        exits its position as fast as possible, such as a sudden change in market
        conditions leading to losses, or an imminent failure in an external
        dependency.

        This may only be called by governance, the guardian, or the Strategy
        itself. Note that a Strategy will only revoke itself during emergency
        shutdown.
    @param strategy The Strategy to revoke.
    """
    assert msg.sender in [strategy, self.governance, self.guardian]
    assert self.strategies[strategy].debtRatio != 0 # dev: already zero

    self._revokeStrategy(strategy)


@external
def addStrategyToQueue(strategy: address):
    """
    @notice
        Adds `strategy` to `withdrawalQueue`.

        This may only be called by governance or management.
    @dev
        The Strategy will be appended to `withdrawalQueue`, call
        `setWithdrawalQueue` to change the order.
    @param strategy The Strategy to add.
    """
    assert msg.sender in [self.governance, self.management], "Only governance or management" # dev: only governance or management
    # Must be current strategy
    assert self.strategies[strategy].activation > 0, "Strategy not active"
    # Can't already be in the queue
    last_idx: uint256 = 0
    for s in self.withdrawalQueue:
        if s == ZERO_ADDRESS:
            break
        assert s != strategy, "Strategy already in queue" # dev: strategy already in queue
        last_idx += 1
    # Check if queue is full
    assert last_idx < MAXIMUM_STRATEGIES, "Withdrawal queue full" # dev: withdrawal queue full

    self.withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy
    self._organizeWithdrawalQueue() # organize the withdrawal queue to remove any gaps
    log StrategyAddedToQueue(strategy) # emit strategy added to queue event


@external
def removeStrategyFromQueue(strategy: address):
    """
    @notice
        Remove `strategy` from `withdrawalQueue`.

        This may only be called by governance or management.
    @dev
        We don't do this with revokeStrategy because it should still
        be possible to withdraw from the Strategy if it's unwinding.
    @param strategy The Strategy to remove.
    """
    assert msg.sender in [self.governance, self.management], "Only governance or management" # dev: only governance or management
    for idx in range(MAXIMUM_STRATEGIES):
        if self.withdrawalQueue[idx] == strategy:
            self.withdrawalQueue[idx] = ZERO_ADDRESS
            self._organizeWithdrawalQueue() # organize the withdrawal queue to remove any gaps
            log StrategyRemovedFromQueue(strategy) # emit strategy removed from queue event
            return
    raise "Strategy not in queue" # dev: strategy not in queue


@view
@internal
def _debtOutstanding(strategy: address) -> uint256:
    # Determines the quantity of debt outstanding for a given Strategy.
    # NOTE: This is the amount that the Strategy owes the Vault, based on
    #       its debt ratio and the total assets managed by the Vault.
    if self.debtRatio == 0:
        return self.strategies[strategy].totalDebt # If no debt ratio, all debt is outstanding beccause no new debt will be given in order to prevent unfair advantage

    strategy_debtLimit: uint256 = (
        self.strategies[strategy].debtRatio
        * self._totalAssets()
        / MAX_BPS
    )
    strategy_totalDebt: uint256 = self.strategies[strategy].totalDebt

    if self.emergencyShutdown:
        return strategy_totalDebt # In emergency shutdown, all debt is outstanding because we want to withdraw everything as fast as possible
    elif strategy_totalDebt <= strategy_debtLimit:
        return 0 # If the strategy is within its debt limit, no debt is outstanding
    else:
        return strategy_totalDebt - strategy_debtLimit # If the strategy is over its debt limit, the excess is outstanding


@view
@external
def debtOutstanding(strategy: address = msg.sender) -> uint256:
    """
    @notice
        Determines if `strategy` is past its debt limit and if any tokens
        should be withdrawn to the Vault.
    @param strategy The Strategy to check. Defaults to the caller.
    @return The quantity of tokens to withdraw.
    """
    return self._debtOutstanding(strategy)


@view
@internal
def _creditAvailable(_name: type):
    # See note on `creditAvailable()`.
    if self.emergencyShutdown:
        return 0  # In emergency shutdown, no new credit is given to strategies
    vault_totalAssets: uint256 = self._totalAssets()
    vault_debtLimit: uint256 = (self.debtRatio * vault_totalAssets) / MAX_BPS
    vault_totalDebt: uint256 = self.totalDebt
    strategy_debtLimit: uint256 = self.strategies[strategy].debtRatio * vault_totalAssets / MAX_BPS
    strategy_totalDebt: uint256 = self.strategies[strategy].totalDebt
    strategy_minDebtPerHarvest: uint256 = self.strategies[strategy].minDebtPerHarvest # minimum debt that the strategy can have after harvest
    strategy_maxDebtPerHarvest: uint256 = self.strategies[strategy].maxDebtPerHarvest # maximum debt that the strategy can have after harvest

    # -------------------------------------------------
    # NOTE: - Strategy’s personal credit limit (debtRatio).
    #       - Vault’s global credit limit (system-wide cap).
    #       - Actual idle tokens available (physical liquidity in vault).
    # -------------------------------------------------

    # NOTE: Exhausted credit line is already at or above its limit so cant borrow more
    if strategy_debtLimit <= strategy_totalDebt or vault_debtLimit <= vault_totalDebt:
        return 0 
    
    # Strat with debt limit left for the strategy
    available: uint256 = strategy_debtLimit - strategy_totalDebt

    # Adjust by the global debt limit left
    available = min(available, vault_debtLimit - vault_totalDebt)

    # Can only borrow up to what the contract has in reserve
    # NOTE: Running near 100% is discouraged
    available = min(available, self.totalIdle)

    # Adjust by min and max borrow limits (per harvest)
    # NOTE: min increase can be used to ensure that if a strategy has a minimum
    #       amount of capital needed to purchase a position, it's not given capital
    #       it can't make use of yet.
    # NOTE: max increase is used to make sure each harvest isn't bigger than what
    #       is authorized. This combined with adjusting min and max periods in
    #       `BaseStrategy` can be used to effect a "rate limit" on capital increase.
    if available < strategy_minDebtPerHarvest:
        return 0
    else:
        return min(available, strategy_maxDebtPerHarvest)


@view
@external
def creditAvailable(strategy: address = msg.sender) -> uint256:
    """
    @notice
        Amount of tokens in Vault a Strategy has access to as a credit line.

        This will check the Strategy's debt limit, as well as the tokens
        available in the Vault, and determine the maximum amount of tokens
        (if any) the Strategy may draw on.

        In the rare case the Vault is in emergency shutdown this will return 0.
    @param strategy The Strategy to check. Defaults to caller.
    @return The quantity of tokens available for the Strategy to draw on.
    """
    return self._creditAvailable(strategy)


@view
@internal
def _expectedReturn(strategy: address) -> uint256:
    # See note on `expectedReturn()`.
    # NOTE: “Given the average rate of return in the past, how much profit should we expect right now if we harvested this second?”
    strategy_lastReport: uint256 = self.strategies[strategy].lastReport
    timeSinceLastHarvest: uint256 = block.timestamp - strategy_lastReport
    totalHarvest: uint256 = strategy_lastReport - self.strategies[strategy].activation

    # NOTE: If either `timeSinceLastHarvest` or `totalHarvestTime` is 0, we can short-circuit to `0`
    if timeSinceLastHavest > 0 and totalHarvest > 0 and Strategy(strategy).isActive():
        # NOTE: Unlikely to throw unless strategy accumalates >1e68 returns
        # NOTE: Calculate average over period of time where harvests have occured in the past
        return (
            self.strategies[strategy].totalGain
            * timeSinceLastHarvest
            / totalHarvest
        )
    else:
        return 0 # Covers the scenario when block.timestamp == activation

    
@view
@external
def availableDepositLimit() -> uint256:
    if self.depositLimit > self._totalAssets():
        return self.depositLimit - self._totalAssets()
    else:
        return 0``
    


@view
@external
def expectedReturn(strategy: address = msg.sender) -> uint256:
    """
    @notice
        Provide an accurate expected value for the return this `strategy`
        would provide to the Vault the next time `report()` is called
        (since the last time it was called).
    @param strategy The Strategy to determine the expected return for. Defaults to caller.
    @return
        The anticipated amount `strategy` should make on its investment
        since its last report.
    """
    return self._expectedReturn(strategy)
    

@internal
def _assessFees(strategy: address, gain: uint256) -> uint256:
    # Issue new shares to cover fees
    # NOTE: In effect, this reduces overall share price by the combined fee
    # NOTE: may throw if Vault.totalAssets() > 1e64, or not called for more than a year
    if self.strategies[strategy].activation == block.timestamp:
        return 0  # No fees on first report

    duration: uint256 = block.timestamp - self.strategies[strategy].lastReport
    assert duration != 0, "Duration cannot be zero" # dev: duration cannot be zero

    if gain == 0:
        return 0  # No fees if no gain

    # Performance fee
    management_fee: uint256 = (
        (
            (self.strategies[strategy].totalDebt - Strategy(strategy).delegatedAssets())
            * duration 
            * self.managementFee
        )
        / MAX_BPS
        / SECS_PER_YEAR
    )

    # NOTE: Applies if Strategy is not shutting down, or it is but all debt paid off
    # NOTE: No fee is taken when a Strategy is unwinding it's position, until all debt is paid
    strategist_fee: uint256 = (
        gain
        * self.strategies[strategy].performanceFee
        / MAX_BPS
    )
    # NOTE: Unlikely to throw unless strategy reports >1e72 harvest profit
    performance_fee: uint256 = gain * self.performanceFee / MAX_BPS

    # NOTE: This must be called prior to taking new collateral,
    #       or the calculation will be wrong!
    # NOTE: This must be done at the same time, to ensure the relative
    #       ratio of governance_fee : strategist_fee is kept intact
    total_fee: uint256 = performance_fee + strategist_fee + management_fee
    if total_fee > gain:
        total_fee = gain  # Cap fees to gain
    if total_fee > 0:  # NOTE: If mgmt fee is 0% and no gains were realized, skip
        reward: uint256 = self._issueSharesForAmount(self, total_fee) # issue shares to cover fees

        # Send the rewards out as new shares in this Vault
        if strategist_fee > 0:
            # NOTE: Unlikely to throw unless sqrt(reward) >>> 1e39
            strategist_reward: uint256 = (
                strategist_fee
                * reward
                / total_fee
            )
            self._transfer(self, strategy, strategist_reward)
            # NOTE: Strategy distributes rewards at the end of harvest()
        # NOTE: Governance earns any dust leftover from flooring math above
        if self.balanceOf[self] > 0:
            self._transfer(self, self.rewards, self.balanceOf[self])
    log FeeReport(management_fee, performance_fee, strategist_fee, duration)
    return total_fee

@external
def report(gain: uint256, loss: uint256, _debtPayment: uint256) -> uint256:
    """
    @notice
        Reports the amount of assets the calling Strategy has free (usually in
        terms of ROI).

        The performance fee is determined here, off of the strategy's profits
        (if any), and sent to governance.

        The strategist's fee is also determined here (off of profits), to be
        handled according to the strategist on the next harvest.

        This may only be called by a Strategy managed by this Vault.
    @dev
        For approved strategies, this is the most efficient behavior.
        The Strategy reports back what it has free, then Vault "decides"
        whether to take some back or give it more. Note that the most it can
        take is `gain + _debtPayment`, and the most it can give is all of the
        remaining reserves. Anything outside of those bounds is abnormal behavior.

        All approved strategies must have increased diligence around
        calling this function, as abnormal behavior could become catastrophic.
    @param gain
        Amount Strategy has realized as a gain on it's investment since its
        last report, and is free to be given back to Vault as earnings
    @param loss
        Amount Strategy has realized as a loss on it's investment since its
        last report, and should be accounted for on the Vault's balance sheet.
        The loss will reduce the debtRatio. The next time the strategy will harvest,
        it will pay back the debt in an attempt to adjust to the new debt limit.
    @param _debtPayment
        Amount Strategy has made available to cover outstanding debt
    @return Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
    """

    # Only approved strategies can call this function
    assert self.strategies[msg.sender].activation > 0, "Strategy not active"
    # No lying about total availablle to withdrawl
    assert self.token.balanceOf(msg.sender) >= gain + _debtPayment, "Insufficient balance to cover report"
    
    # Report a loss
    if loss > 0:
        self._reportLoss(msg.sender, loss) # based on loss in user withdrawal

    # Assess both management and performance fees, based on shares vault
    totalFees: uint256 = self._assessFees(msg.sender, gain)

    # Returns are always "realized gains"
    self.strategies[msg.sender].totalGain += gain # the total gain the strategy has made over its lifetime

    # Compute the line of credit the Vault is able to offer the strategy (if any)
    credit: uint256 = self._creditAvailable(msg.sender)

    # Outstanding debt the Strategy wants to take back from the Vault (if any)
    # NOTE: debtOutstanding <= StrategyParams.totalDebt
    debt: uint256 = self._debtOutstanding(msg.sender)
    debtPayment: uint256 = min(debt, _debtPayment) # can't pay more than the debt

    if debtPayment > 0:
        self.strategies[msg.sender].totalDebt -= debtPayment # reduce the strategy's total debt by the amount paid
        self.totalDebt -= debtPayment # reduce the vault's total debt by the amount paid
        debt -= debtPayment # reduce the outstanding debt by the amount paid
        # NOTE: `debt` is being tracked for later

    # Update the actual debt based on the full credit we are extending to the Strategy
    # or the returns if we are taking funds back
    # NOTE: credit + self.strategies[msg.sender].totalDebt is always < self.debtLimit
    # NOTE: At least one of `credit` or `debt` is always 0 (both can be 0)
    if credit > 0:
        self.strategies[msg.sender].totalDebt += credit
        self.totalDebt += credit
        # NOTE: We don't need to check for overflow above because totalDebt is
        #       capped by debtRatio of MAX_BPS, which is applied to totalAssets()
        #       which is capped by the max uint256.
    
    # Give/take balance to Strategy, based on the difference between the reported gains
    # (if any), the debt payment (if any), the credit increase we are offering (if any),
    # and the debt needed to be paid off (if any)
    # NOTE: This is just used to adjust the balance of tokens between the Strategy and
    #       the Vault based on the Strategy's debt limit (as well as the Vault's).
    totalAvail: uint256 = gain + debtPayment
    if totalAvail < credit:
        self.totalIdle -= credit - totalAvail # reduce idle by the amount we are giving to the strategy
        self.erc20_safe_transfer(self.token.address, msg.sender, credit - totalAvail)
    elif totalAvail > credit:
        # NOTE: We don't need to check for underflow here because we checked that
        #       totalAvail <= self.token.balanceOf(msg.sender) at the start of the function
        self.totalIdle += totalAvail - credit # increase idle by the amount we are taking from the strategy
        self.erc20_safe_transferFrom(self.token.address, msg.sender, self, totalAvail - credit)
    # else, don't do anything because it is balanced

    # Profit is locked and gradually released per block
    # NOTE: compute current locked profit and replace with sum of current and new
    lockedProfitBeforeLoss: uint256 = self._calculateLockedProfit() + gain - totalFees
    if lockedProfitBeforeLoss > loss: 
        self.lockedProfit = lockedProfitBeforeLoss - loss
    else:
        self.lockedProfit = 0

    # Update reporting time
    self.strategies[msg.sender].lastReport = block.timestamp
    self.lastReport = block.timestamp

    log StrategyReported(
        msg.sender,
        gain,
        loss,
        debtPayment,
        self.strategies[msg.sender].totalGain,
        self.strategies[msg.sender].totalLoss,
        self.strategies[msg.sender].totalDebt,
        credit,
        self.strategies[msg.sender].debtRatio,
    )

    if self.strategies[msg.sender].debtRatio == 0 or self.emergencyShutdown:
        # Take every last penny the Strategy has (Emergency Exit/revokeStrategy)
        # NOTE: This is different than `debt` in order to extract *all* of the returns
        return Strategy(msg.sender).estimatedTotalAssets()
    else:
        # Otherwise, just return what we have as debt outstanding
        return debt


@external
def sweep(token: address, amount: uint256 = MAX_UINT256):
    """
    @notice
        Removes tokens from this Vault that are not the type of token managed
        by this Vault. This may be used in case of accidentally sending the
        wrong kind of token to this Vault.

        Tokens will be sent to `governance`.

        This will fail if an attempt is made to sweep the tokens that this
        Vault manages.

        This may only be called by governance.
    @param token The token to transfer out of this vault.
    @param amount The quantity or tokenId to transfer out.
    """
    assert msg.sender == self.governance, "Only governance" # dev: only governance
    # Can't sweep the token the vault is working with\
    value: uint256 = amount
    if value == MAX_UINT256:
        value = ERC20(token).balanceOf(self)

    if token == self.token.address:
        value = self.token.balanceOf(self) - self.totalIdle

    log Sweep(token, value)
    safe.erc20_safe_transfer(token, self.governance, value)


    
    
    




             


        