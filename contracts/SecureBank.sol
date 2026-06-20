// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SecureBank
 * @notice Fixed version of VulnerableBank for educational and defensive demonstration
 * @dev Uses CEI pattern + ReentrancyGuard + proper access control
 */
contract SecureBank is ReentrancyGuard {
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;
    address public owner;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ── Deposit ────────────────────────────────────────────────────────
    function deposit() public payable {
        require(msg.value > 0, "Send ETH to deposit");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // ── SECURE withdraw ────────────────────────────────────────────────
    // FIXES:
    // 1. nonReentrant modifier prevents recursive re-entry
    // 2. state updated BEFORE external call (CEI pattern)
    // 3. low-level call result is checked
    function withdraw(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Effects first
        balances[msg.sender] -= _amount;
        totalDeposits -= _amount;

        // Interaction last
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, _amount);
    }

    // ── SECURE emergency drain ─────────────────────────────────────────
    // FIX: restricted to owner only
    function emergencyDrain() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds available");

        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "Drain failed");

        emit EmergencyWithdrawal(owner, amount);
    }

    // ── Ownership management ───────────────────────────────────────────
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ── View helpers ───────────────────────────────────────────────────
    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        revert("Invalid call");
    }
}
