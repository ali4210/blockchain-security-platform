/**
 * reentrancy_demo.js
 * ==================
 * Demonstrates the reentrancy attack live using Hardhat local blockchain.
 *
 * Run: npx hardhat run demos/reentrancy_demo.js --network localhost
 *
 * Author  : Saleem Ali
 * Program : Al-Nafi AIOps Level 6 — Topic 124
 */

const { ethers } = require("hardhat");

async function main() {
  const [deployer, attacker] = await ethers.getSigners();

  console.log("\n╔══════════════════════════════════════════════════════════╗");
  console.log("║   REENTRANCY ATTACK DEMONSTRATION                        ║");
  console.log("║   Al-Nafi AIOps Level 6  ·  Topic 124  ·  Saleem Ali    ║");
  console.log("╚══════════════════════════════════════════════════════════╝\n");

  // ── 1. Deploy VulnerableBank ─────────────────────────────────────────
  console.log("STEP 1: Deploying VulnerableBank...");
  const VulnerableBank = await ethers.getContractFactory("VulnerableBank");
  const bank = await VulnerableBank.deploy();
  await bank.deployed();
  console.log(`        ✓ Deployed at: ${bank.address}`);

  // ── 2. Innocent users deposit funds ──────────────────────────────────
  console.log("\nSTEP 2: Innocent users deposit into VulnerableBank...");
  const user1 = deployer;
  await bank.connect(user1).deposit({ value: ethers.utils.parseEther("5.0") });
  let contractBal = await bank.getContractBalance();
  console.log(`        ✓ Bank balance: ${ethers.utils.formatEther(contractBal)} ETH`);

  // ── 3. Deploy attacker contract ───────────────────────────────────────
  console.log("\nSTEP 3: Deploying AttackerContract...");
  const AttackerContract = await ethers.getContractFactory("AttackerContract");
  const attackerContract = await AttackerContract.connect(attacker).deploy(bank.address);
  await attackerContract.deployed();
  console.log(`        ✓ Attacker contract at: ${attackerContract.address}`);

  // ── 4. Record balances before attack ─────────────────────────────────
  const bankBefore     = await bank.getContractBalance();
  const attackerBefore = await attacker.getBalance();
  console.log("\nSTEP 4: Balances BEFORE attack:");
  console.log(`        Bank balance     : ${ethers.utils.formatEther(bankBefore)} ETH`);
  console.log(`        Attacker balance : ${ethers.utils.formatEther(attackerBefore)} ETH`);

  // ── 5. Execute the attack ─────────────────────────────────────────────
  console.log("\nSTEP 5: Executing reentrancy attack...");
  console.log("        [Attacker deposits 1 ETH then calls withdraw()]");
  console.log("        [Each withdraw triggers receive() which calls withdraw() again]");
  const tx = await attackerContract.connect(attacker).attack({
    value: ethers.utils.parseEther("1.0"),
    gasLimit: 3_000_000,
  });
  await tx.wait();

  // ── 6. Record balances after attack ──────────────────────────────────
  const bankAfter     = await bank.getContractBalance();
  const attackerAfter = await attackerContract.getBalance();
  console.log("\nSTEP 6: Balances AFTER attack:");
  console.log(`        Bank balance          : ${ethers.utils.formatEther(bankAfter)} ETH`);
  console.log(`        Attacker contract bal : ${ethers.utils.formatEther(attackerAfter)} ETH`);

  const stolen = ethers.utils.formatEther(attackerAfter);
  console.log(`\n⚠️  ATTACK RESULT: ${stolen} ETH stolen from innocent depositors!`);

  // ── 7. Summary ────────────────────────────────────────────────────────
  console.log("\n════════════════════════════════════════════════════════════");
  console.log("  WHY THE ATTACK WORKED:");
  console.log("  1. withdraw() sends ETH BEFORE updating balances[msg.sender]");
  console.log("  2. Attacker's receive() calls withdraw() again recursively");
  console.log("  3. Balance check passes each time (state not updated yet)");
  console.log("");
  console.log("  HOW SecureBank PREVENTS THIS:");
  console.log("  1. nonReentrant modifier blocks recursive calls");
  console.log("  2. CEI pattern: state updated BEFORE ETH transfer");
  console.log("════════════════════════════════════════════════════════════\n");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
