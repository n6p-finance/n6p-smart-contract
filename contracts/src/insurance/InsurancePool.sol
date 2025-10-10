// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract InsurancePool is Ownable {
    IERC20 public token;
    uint256 public totalFees;
    mapping(address => bool) public governanceAddresses;

    event FeeDeposited(uint256 amount);
    event FeeClaimed(address indexed to, uint256 amount);

    modifier onlyGovernance() {
        require(governanceAddresses[msg.sender], "Not governance");
        _;
    }

    constructor(IERC20 _token, address _initialOwner) Ownable(_initialOwner) {
        token = _token;
        governanceAddresses[_initialOwner] = true; // Initial owner is governance
    }

    function setGovernanceAddress(address _governance, bool _status) external onlyOwner {
        governanceAddresses[_governance] = _status;
    }

    function depositFee(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        totalFees += amount;
        emit FeeDeposited(amount);
    }

    function claimFee(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient pool balance");
        require(token.transfer(to, amount), "Transfer failed");
        emit FeeClaimed(to, amount);
    }

    function poolBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}