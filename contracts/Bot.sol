// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "./lib/PBSState.sol";
import "./lib/PCSHelpers.sol";
import "./lib/Constants.sol";

contract Bot is PCSHelpers {
    constructor(address preparer, address seller) PCSHelpers(preparer, seller) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    fallback() external payable {}

    receive() external payable {}

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin can withdraw"
        );
        payable(msg.sender).transfer(balance());
    }

    function withdrawToken(address token, address withdrawTo) external {
        require(hasRole(SELL_ROLE, msg.sender), "Only seller can withdraw");

        IERC20 tokenContract = IERC20(token);
        uint256 withdrawWholeAmount = tokenContract.balanceOf(address(this));
        require(withdrawWholeAmount > 0, "Nothing to withdraw");

        Utils.approve(tokenContract, address(this), withdrawWholeAmount);
        Utils.approve(tokenContract, msg.sender, withdrawWholeAmount);

        tokenContract.transferFrom(
            address(this),
            withdrawTo,
            withdrawWholeAmount
        );
    }

    function prep(
        address liquidityToken,
        address token,
        uint256 buyAmount,
        bool skipTest,
        uint256 testThreshold,
        uint256 sellCount,
        uint256 firstSellPercent,
        uint256 percentOfTokensToKeep,
        uint256 buyLimit
    ) external {
        require(
            hasRole(PREPARE_ROLE, msg.sender),
            "Only preparer can call this function"
        );

        resetState();

        tokenConfig = TokenConfig(
            skipTest,
            Math.min(buyAmount, balance()),
            buyLimit,
            testThreshold,
            sellCount,
            firstSellPercent,
            percentOfTokensToKeep,
            liquidityToken,
            token
        );
        enforcePrepareInvariants();
    }

    // this gives us option to have a funky name when buying
    function cure() external {
        buy();
    }

    function buy() private {
        enforceBuyInvariants(balance());

        address liquidityToken = getLiquidityToken(
            tokenConfig.token,
            tokenConfig.liquidityToken
        );
        require(liquidityToken != address(0), "No liquidity token found");

        tokenConfig.liquidityToken = liquidityToken;

        checkIfTokenIsBad();
        if (state.badToken) {
            return;
        }

        tokenConfig.buyAmount = PCSHelpers.calculateMaxAmountIn(tokenConfig);

        buyHelper();

        state.totalTokenBought = IERC20(tokenConfig.token).balanceOf(
            address(this)
        );

        if (state.totalTokenBought > 0) {
            state.tokenBought = true;
        }
    }

    function sell() external {
        require(
            hasRole(SELL_ROLE, msg.sender),
            "Only seller can call this function"
        );

        enforceSellInvariants();

        sellHelper();
        state.soldCount++;
    }

    function sellAll(address token) external {
        require(
            hasRole(SELL_ROLE, msg.sender),
            "Only seller can call this function"
        );
        resetState();

        tokenConfig.token = token;
        tokenConfig.liquidityToken = getLiquidityToken(
            tokenConfig.token,
            Constants.WBNB
        );
        tokenConfig.sellCount = 1;
        tokenConfig.firstSellPercent = 100;
        tokenConfig.percentOfTokensToKeep = 0;

        sellHelper();
    }

    function checkIfTokenIsBad() private {
        if (tokenConfig.skipTest) {
            state.badToken = false;
            return;
        }

        state.isBadTokenTest = true;

        uint256 balanceBefore = balance();
        buyHelper();

        if (state.gasError) {
            state.badToken = true;
            state.isBadTokenTest = false;
            return;
        }

        sellHelper();
        uint256 balanceAfter = balance();

        uint256 threshold = (tokenConfig.testThreshold *
            Constants.BAD_TOKEN_TEST_AMT) / 100;
        state.badToken = balanceAfter < balanceBefore - threshold;

        state.isBadTokenTest = false;
    }

    function liqAlreadyAdded(address token) external view returns (bool) {
        return checkIfLiqudityWasAlreadyAdded(token, Constants.WBNB);
    }
}
