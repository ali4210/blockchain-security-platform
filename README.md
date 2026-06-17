# 🔐 Advanced Blockchain Security Platform

[![Security Scan](https://github.com/ali4210/blockchain-security-platform/actions/workflows/security-scan.yml/badge.svg)](https://github.com/ali4210/blockchain-security-platform/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.0-orange)](https://soliditylang.org)
[![Python](https://img.shields.io/badge/Python-3.10-blue)](https://python.org)

> **Topic 124 — EduQual Level 6 Oral Presentation**
> Diploma in Artificial Intelligence Operations
> Al-Nafi International College
> **Student:** Saleem Ali

---

## 📋 Project Overview

A comprehensive blockchain security platform demonstrating:

- ✅ **AI-Powered Smart Contract Auditing** — automated vulnerability detection
- ✅ **DeFi Attack Prevention** — flash loan, front-running, rug pull detection
- ✅ **Consensus Attack Monitoring** — 51% attack & selfish mining detection
- ✅ **DevSecOps Integration** — automated CI/CD security pipeline
- ✅ **Wallet & Key Security** — multi-sig, HSM, threshold cryptography concepts
- ✅ **Compliance Automation** — AML/KYC monitoring concepts

---

## 📁 Project Structure

```
blockchain-security-platform/
│
├── contracts/                        # Smart contracts
│   ├── VulnerableBank.sol            # Intentionally vulnerable (demo)
│   ├── SecureBank.sol                # Fixed secure version
│   └── FlashLoanVulnerable.sol       # DeFi attack demonstration
│
├── scanners/                         # Security scanning tools
│   └── security_scanner.py          # Automated Slither scanner
│
├── demos/                            # Attack demonstration scripts
│   └── reentrancy_demo.js           # Hardhat reentrancy demo
│
├── reports/                          # Generated scan reports (auto-created)
│
├── .github/workflows/
│   └── security-scan.yml            # CI/CD security pipeline
│
├── docs/
│   └── SETUP_GUIDE.md               # Full setup instructions
│
└── README.md
```

---

## 🚀 Quick Start (Kali Linux)

### Step 1 — Clone the repository
```bash
git clone https://github.com/ali4210/blockchain-security-platform.git
cd blockchain-security-platform
```

### Step 2 — Install dependencies
```bash
# Python tools
pip install slither-analyzer

# Node.js tools
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
```

### Step 3 — Run the security scan
```bash
python3 scanners/security_scanner.py
```

### Step 4 — View results
```bash
cat reports/scan_report_*.json
```

---

## 🔍 Demo: Scanning a Vulnerable Contract

```bash
$ python3 scanners/security_scanner.py contracts/VulnerableBank.sol

╔══════════════════════════════════════════════════════════════╗
║   BLOCKCHAIN SECURITY SCANNER  v1.0                          ║
║   Al-Nafi AIOps Level 6  ·  Topic 124  ·  Saleem Ali        ║
╚══════════════════════════════════════════════════════════════╝

[✓] Slither found

  Scanning : VulnerableBank.sol
  ────────────────────────────────────────────────────────────────

  [!] 3 issue(s) found:

  Issue #1
    Severity   : High
    Type       : reentrancy-eth
    Detail     : VulnerableBank.withdraw re-entrancy vulnerability...

  Issue #2
    Severity   : Medium
    Type       : missing-zero-check
    Detail     : Missing access control on emergencyDrain...

  Overall Risk : CRITICAL — DO NOT DEPLOY
```

---

## 🛡️ Vulnerability Comparison

| Vulnerability | VulnerableBank.sol | SecureBank.sol |
|---|---|---|
| Reentrancy Attack | ❌ VULNERABLE | ✅ FIXED |
| Missing Access Control | ❌ VULNERABLE | ✅ FIXED |
| Unchecked External Call | ❌ VULNERABLE | ✅ FIXED |

**Fix applied:** Checks-Effects-Interactions pattern + `nonReentrant` modifier + `onlyOwner` modifier

---

## ⚙️ CI/CD Security Pipeline

Every push to `main` automatically triggers:

```
Code Push → Slither Scan → Security Gate → Deploy (if passed)
                ↓
        BLOCK if HIGH severity found
```

View pipeline results: [GitHub Actions Tab](../../actions)

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| [Slither](https://github.com/crytic/slither) | Static smart contract analysis |
| [Mythril](https://github.com/ConsenSys/mythril) | Symbolic execution analysis |
| [Hardhat](https://hardhat.org) | Local blockchain development |
| [OpenZeppelin](https://openzeppelin.com) | Secure contract libraries |
| [GitHub Actions](https://github.com/features/actions) | CI/CD automation |

---

## 📚 Key Concepts Demonstrated

### Reentrancy Attack
```
Attacker deposits 1 ETH → calls withdraw()
→ contract sends ETH → attacker's receive() calls withdraw() AGAIN
→ before balance is updated → repeated until contract is drained
```

### Fix: Checks-Effects-Interactions
```solidity
// CHECKS
require(balances[msg.sender] >= _amount);
// EFFECTS (state update FIRST)
balances[msg.sender] -= _amount;
// INTERACTIONS (external call LAST)
(bool ok,) = msg.sender.call{value: _amount}("");
```

---

## 👤 Author

**Saleem Ali**
- GitHub: [@ali4210](https://github.com/ali4210)
- LinkedIn: [saleem-ali-189719325](https://linkedin.com/in/saleem-ali-189719325)
- Program: Diploma in AI Operations — Al-Nafi International College

---

> ⚠️ **Disclaimer:** Vulnerable contracts are for educational purposes only.
> Never deploy them to any live network.
