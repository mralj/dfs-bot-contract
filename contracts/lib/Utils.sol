// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../external/IWBNB.sol";
import "../external/pcsv2/IPCSV2Router.sol";

import "./Constants.sol";
import "./Types.sol";

library Utils {
    function sortTokens(address token0, address token1)
        internal
        pure
        returns (address tokenA, address tokenB)
    {
        (tokenA, tokenB) = token0 < token1
            ? (token0, token1)
            : (token1, token0);
    }

    function approve(
        IERC20 tokenContract,
        address toWhomWeAreGivingApproval,
        uint256 amount
    ) internal {
        address whoIsApproving = address(this);

        if (
            tokenContract.allowance(
                whoIsApproving,
                toWhomWeAreGivingApproval
            ) >= amount
        ) {
            return;
        }

        bool approvalSucceeded = tokenContract.approve(
            toWhomWeAreGivingApproval,
            tokenContract.totalSupply()
        );

        require(approvalSucceeded, "Approval failed");
    }

    function unwrapBNB() internal {
        IWBNB(Constants.WBNB).withdraw(
            IERC20(Constants.WBNB).balanceOf(address(this))
        );
    }

    function gasAllowance() internal view returns (uint256) {
        return gasleft() - Constants.GAS_NEEDED_TO_UPDATE_GAS_ERR_FLAG;
    }

    function notEnoughGas() internal view returns (bool) {
        uint256 gasNeededWithBuffer = (Constants
            .GAS_NEEDED_TO_UPDATE_GAS_ERR_FLAG * 150) / 100;
        return gasleft() <= gasNeededWithBuffer;
    }

    function calculateHowManyTokensToSell(
        State memory state,
        TokenConfig memory tc
    ) internal view returns (uint256) {
        uint256 currentTokenBalance = IERC20(tc.token).balanceOf(address(this));
        if (state.isBadTokenTest) {
            return makeSureNotToTransferWholeAmount(currentTokenBalance);
        }

        uint256 tokenCount = getTokenAmountAvailableToSell(
            state,
            tc,
            currentTokenBalance
        );

        bool thisIsTheLastSellSoSellAllTheTokens = state.soldCount ==
            tc.sellCount - 1;
        if (thisIsTheLastSellSoSellAllTheTokens) {
            return makeSureNotToTransferWholeAmount(tokenCount);
        }

        bool thisIsFirstSellHandleItSpecially = state.soldCount == 0;
        if (thisIsFirstSellHandleItSpecially) {
            uint256 tokenCountToSellFirstTime = (tokenCount *
                tc.firstSellPercent) / 100;
            return tokenCountToSellFirstTime;
        }

        uint256 sellsLeft = tc.sellCount - state.soldCount;
        return tokenCount / sellsLeft;
    }

    function getTokenAmountAvailableToSell(
        State memory state,
        TokenConfig memory tc,
        uint256 currentTokenBalance
    ) internal pure returns (uint256) {
        if (tc.percentOfTokensToKeep == 0) {
            return currentTokenBalance;
        }

        if (tc.percentOfTokensToKeep == 100) {
            return 0;
        }

        return
            currentTokenBalance -
            (state.totalTokenBought * tc.percentOfTokensToKeep) /
            100;
    }

    // anti-anti-bot measure
    // some tokens have measure such that if you want to transfer the whole amount
    // you simply cannot, this is protection again that
    function makeSureNotToTransferWholeAmount(uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return (amount * 9999) / 10000;
    }

    function handleErrorWhenCallingPCSSwap(
        State storage state,
        string memory error
    ) internal {
        if (Utils.notEnoughGas()) {
            state.gasError = true;
        } else {
            revert(error);
        }
    }
}
