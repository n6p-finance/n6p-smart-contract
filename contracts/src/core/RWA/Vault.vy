"""
@title Napfi Token Vault (ERC-7540)
@license GNU AGPLv3
@author rudeus33
@notice
    Napfi Token Vault
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
    # @notice lockedProfitDegradation 
    lockedProfitDegradation: uint256 # new based on the locked profit degradation

event WithdrawFromStrategy:
    strategy: indexed(address)
    totalDebt: uint256
    loss: uint256

event UpdateGovernance:
    governance: address

event UpdateManagement:
    management: address

event UpdateRewards:
    rewards: address # New active rewards recipient

event UpdateGuardian:
    guardian: address # address of the active guardian

event EmergencyShutdown:
    active: bool

event UpdateWithdrawalQueue:
    queue: address[MAXIMUM_STRATEGIES]

event StrategyUpdateDebtRatio:
    strategy: indexed(address)
    debtRatio: uint256

event StrategyUpdateMinDebtPerHarvest:
    strategy: indexed(address)
    minDebtPerHarvest: uint256

event RequestDeposit:
    controller: indexed(address)
    owner: indexed(address)
    requestId: indexed(uint256)
    sender: indexed(address)
    amount: uint256