// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Constants {
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint256 constant BLOCK_TIME_IN_SECONDS = 3 seconds;
    uint256 constant PCS_TTL = BLOCK_TIME_IN_SECONDS;
    uint256 constant BAD_TOKEN_TEST_AMT = 10000000000000;
    uint256 constant GAS_NEEDED_TO_UPDATE_GAS_ERR_FLAG = 100000;
}
