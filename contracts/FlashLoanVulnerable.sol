// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FlashLoanVulnerableDEX
 * @notice Demonstrates price oracle manipulation via flash loan
 * @dev Topic 124 Demo — Al-Nafi AIOps Level 6 — Saleem Ali
 *
 * Vulnerability: Uses spot balance as price oracle → manipulatable
 */
contract FlashLoanVulnerableDEX {

    uint256 public tokenReserve;
    uint256 public ethReserve;

    mapping(address => uint256) public tokenBalances;

    event Swap(address indexed user, uint256 ethIn, uint256 tokensOut);
    event PriceManipulated(uint256 before, uint256 after_);

    constructor() payable {
        ethReserve   = msg.value;
        tokenReserve = 1_000_000 * 1e18;   // 1M tokens
        tokenBalances[address(this)] = tokenReserve;
    }

    // ── VULNERABLE price feed ──────────────────────────────────────────
    // BUG: price derived from current balance — flash loan can shift it!
    function getPrice() public view returns (uint256) {
        require(ethReserve > 0, "No liquidity");
        return (tokenReserve * 1e18) / ethReserve;
    }

    function swap() external payable {
        require(msg.value > 0, "Send ETH");
        uint256 price      = getPrice();
        uint256 tokensOut  = (msg.value * 1e18) / price;
        require(tokenBalances[address(this)] >= tokensOut, "Not enough tokens");
        tokenBalances[address(this)] -= tokensOut;
        tokenBalances[msg.sender]    += tokensOut;
        ethReserve   += msg.value;
        tokenReserve -= tokensOut;
        emit Swap(msg.sender, msg.value, tokensOut);
    }

    function getContractETH() external view returns (uint256) { return address(this).balance; }
}
