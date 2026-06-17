// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SecureBank
 * @notice FIXED version of VulnerableBank — all 3 vulnerabilities patched
 * @dev Topic 124 Demo — Al-Nafi AIOps Level 6 — Saleem Ali
 *
 * Fixes applied:
 *  1. ReentrancyGuard (nonReentrant modifier)
 *  2. Checks-Effects-Interactions pattern
 *  3. onlyOwner access control on emergencyDrain
 */
contract SecureBank {

    mapping(address => uint256) public balances;
    uint256 public totalDeposits;
    address public owner;

    // ── Reentrancy guard ───────────────────────────────────────────────
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    // ── Access control ─────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value > 0, "Send ETH to deposit");
        balances[msg.sender] += msg.value;
        totalDeposits        += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // ── SECURE withdraw ────────────────────────────────────────────────
    // FIX 1: nonReentrant blocks recursive calls
    // FIX 2: CEI — state updated BEFORE external call
    function withdraw(uint256 _amount) public nonReentrant {
        // CHECKS
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // EFFECTS — update state first ✅
        balances[msg.sender] -= _amount;
        totalDeposits        -= _amount;

        // INTERACTIONS — external call last ✅
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, _amount);
    }

    // ── SECURE emergency drain ─────────────────────────────────────────
    // FIX 3: onlyOwner modifier ✅
    function emergencyDrain() public onlyOwner {
        uint256 bal = address(this).balance;
        (bool ok, ) = msg.sender.call{value: bal}("");
        require(ok, "Drain failed");
    }

    function getMyBalance()       public view returns (uint256) { return balances[msg.sender]; }
    function getContractBalance() public view returns (uint256) { return address(this).balance; }

    receive() external payable { deposit(); }
    fallback() external payable { deposit(); }
}
