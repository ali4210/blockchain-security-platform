#!/usr/bin/env python3
"""
security_scanner.py
====================
Automated smart-contract security scanner for Topic 124 demo.
Runs Slither on every .sol file in contracts/ and saves a JSON report.

Usage (Kali Linux):
    python3 scanners/security_scanner.py
    python3 scanners/security_scanner.py contracts/VulnerableBank.sol

Author  : Saleem Ali
Program : Al-Nafi AIOps Level 6
Topic   : 124 — Advanced Blockchain Security Platform
"""

import subprocess, json, os, sys, glob
from datetime import datetime
from pathlib import Path

# ── terminal colours ────────────────────────────────────────────────────
R  = "\033[91m"; Y  = "\033[93m"; G  = "\033[92m"
C  = "\033[96m"; B  = "\033[94m"; W  = "\033[0m";  BD = "\033[1m"

SEV_COLOR = {"High": R, "Medium": Y, "Low": C, "Informational": W}

def banner():
    print(f"""
{B}{BD}╔══════════════════════════════════════════════════════════════╗
║   BLOCKCHAIN SECURITY SCANNER  v1.0                          ║
║   Al-Nafi AIOps Level 6  ·  Topic 124  ·  Saleem Ali        ║
╚══════════════════════════════════════════════════════════════╝{W}
""")

def check_slither() -> bool:
    try:
        subprocess.run(["slither","--version"], capture_output=True, check=True, timeout=5)
        print(f"{G}[✓] Slither found{W}")
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        print(f"{R}[✗] Slither not installed!{W}")
        print(f"    Run: {Y}pip install slither-analyzer{W}")
        return False

def scan_contract(sol_path: str) -> dict:
    path = Path(sol_path)
    print(f"\n{B}{'─'*64}")
    print(f"  Scanning : {path.name}")
    print(f"  Time     : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'─'*64}{W}")

    result = subprocess.run(
        ["slither", str(path), "--json", "-"],
        capture_output=True, text=True, timeout=120
    )

    vulns = []
    severity_count = {"High": 0, "Medium": 0, "Low": 0, "Informational": 0}

    if result.stdout:
        try:
            data = json.loads(result.stdout)
            detectors = data.get("results", {}).get("detectors", [])

            if not detectors:
                print(f"{G}  [✓] No vulnerabilities detected{W}")
            else:
                print(f"{R}  [!] {len(detectors)} issue(s) found:{W}\n")
                for i, d in enumerate(detectors, 1):
                    sev  = d.get("impact", "Unknown")
                    conf = d.get("confidence", "Unknown")
                    chk  = d.get("check", "unknown")
                    desc = d.get("description", "").strip()[:200]
                    col  = SEV_COLOR.get(sev, W)
                    severity_count[sev] = severity_count.get(sev, 0) + 1
                    print(f"  {col}{BD}Issue #{i}{W}")
                    print(f"    Severity   : {col}{sev}{W}")
                    print(f"    Confidence : {conf}")
                    print(f"    Type       : {chk}")
                    print(f"    Detail     : {desc}\n")
                    vulns.append({"severity": sev, "confidence": conf,
                                  "type": chk, "description": desc})
        except json.JSONDecodeError:
            print(f"{Y}  [!] Could not parse Slither JSON output{W}")
    else:
        print(f"{Y}  [!] Slither produced no output — check contract syntax{W}")

    # ── risk level ──────────────────────────────────────────────────────
    if severity_count["High"] > 0:
        risk, risk_col = "CRITICAL — DO NOT DEPLOY", R
    elif severity_count["Medium"] > 0:
        risk, risk_col = "HIGH — Fix before deploying", Y
    elif severity_count["Low"] > 0:
        risk, risk_col = "MEDIUM — Review recommended", C
    else:
        risk, risk_col = "LOW — Looks clean", G

    print(f"\n  {BD}Overall Risk : {risk_col}{risk}{W}\n")

    return {
        "contract"        : str(path),
        "scanned_at"      : datetime.now().isoformat(),
        "vulnerabilities" : vulns,
        "severity_count"  : severity_count,
        "risk_level"      : risk,
    }

def save_report(results: list):
    os.makedirs("reports", exist_ok=True)
    ts   = datetime.now().strftime("%Y%m%d_%H%M%S")
    out  = f"reports/scan_report_{ts}.json"
    with open(out, "w") as f:
        json.dump({"scan_time": ts, "results": results}, f, indent=2)
    print(f"{G}[✓] Report saved → {out}{W}")
    return out

def main():
    banner()

    if not check_slither():
        sys.exit(1)

    # targets: CLI arg OR all .sol files in contracts/
    if len(sys.argv) > 1:
        targets = sys.argv[1:]
    else:
        targets = sorted(glob.glob("contracts/*.sol"))
        if not targets:
            print(f"{R}[✗] No .sol files found in contracts/{W}")
            sys.exit(1)

    print(f"\n{C}[*] Contracts to scan: {len(targets)}{W}")

    all_results = []
    for sol in targets:
        if not os.path.exists(sol):
            print(f"{R}[✗] File not found: {sol}{W}")
            continue
        all_results.append(scan_contract(sol))

    save_report(all_results)

    # ── final summary ────────────────────────────────────────────────────
    total_high = sum(r["severity_count"].get("High",0)   for r in all_results)
    total_med  = sum(r["severity_count"].get("Medium",0) for r in all_results)
    total_low  = sum(r["severity_count"].get("Low",0)    for r in all_results)

    print(f"\n{BD}{'═'*64}")
    print(f"  SCAN COMPLETE — {len(all_results)} contract(s) analysed")
    print(f"  High   : {R}{total_high}{W}")
    print(f"  Medium : {Y}{total_med}{W}")
    print(f"  Low    : {C}{total_low}{W}")
    print(f"{'═'*64}{W}\n")

if __name__ == "__main__":
    main()
