// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct State {
    bool gasError;
    bool badToken;
    bool tokenBought;
    bool isBadTokenTest;
    uint256 soldCount;
    uint256 totalTokenBought;
    address latestTokenBought;
}

struct TokenConfig {
    bool skipTest;
    uint256 buyAmount;
    uint256 tokenBuyLimit;
    uint256 testThreshold;
    uint256 sellCount;
    uint256 firstSellPercent;
    uint256 percentOfTokensToKeep;
    address liquidityToken;
    address token;
}
