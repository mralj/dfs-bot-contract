// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../external/pcsv2/IPCSV2Factory.sol";
import "../external/pcsv2/IPCSV2Pair.sol";

import "./Constants.sol";
import "./Utils.sol";
import "./Types.sol";

library PCSV2Helpers {
    address constant PCS_V2_FACTORY =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    address constant PCS_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function liquidityAdded(address token0, address token1)
        internal
        view
        returns (bool)
    {
        (uint256 k, , ) = getReserves(token0, token1);

        return k > 0;
    }

    function getReserves(address token0, address token1)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (address firstToken, address secondToken) = Utils.sortTokens(
            token0,
            token1
        );

        address pairAddress = IPCSV2Factory(PCS_V2_FACTORY).getPair(
            firstToken,
            secondToken
        );

        if (pairAddress == address(0)) {
            return (0, 0, 0);
        }

        IPCSV2Pair pair = IPCSV2Pair(pairAddress);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        return (pair.kLast(), reserve0, reserve1);
    }

    function buy(State storage state, TokenConfig memory tc) internal {
        Utils.approve(IERC20(tc.liquidityToken), PCS_V2_ROUTER, tc.buyAmount);

        uint256 minAmountOut = 0;
        uint256 buyAmount = tc.buyAmount;
        address[] memory path = generateBuyPath(tc);

        if (state.isBadTokenTest) {
            buyAmount = Constants.BAD_TOKEN_TEST_AMT;
        }

        try
            IPCSV2Router(PCS_V2_ROUTER)
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: buyAmount,
                gas: Utils.gasAllowance()
            }(
                minAmountOut,
                path,
                address(this),
                block.timestamp + Constants.PCS_TTL
            )
        {} catch Error(string memory reason) {
            Utils.handleErrorWhenCallingPCSSwap(state, reason);
        } catch {
            Utils.handleErrorWhenCallingPCSSwap(
                state,
                "Lowlevel err: PCS V2 buy failed"
            );
        }
    }

    function sell(State storage state, TokenConfig memory tc) internal {
        address[] memory path;
        uint256 minAmountOut = 0;

        uint256 sellAmount = Utils.calculateHowManyTokensToSell(state, tc);
        Utils.approve(IERC20(tc.token), PCS_V2_ROUTER, sellAmount);

        if (tc.liquidityToken == Constants.WBNB) {
            path = new address[](2);
            path[0] = tc.token;
            path[1] = tc.liquidityToken;
        } else {
            path = new address[](3);
            path[0] = tc.token;
            path[1] = tc.liquidityToken;
            path[2] = Constants.WBNB;
        }

        try
            IPCSV2Router(PCS_V2_ROUTER)
                .swapExactTokensForETHSupportingFeeOnTransferTokens{
                gas: Utils.gasAllowance()
            }(
                sellAmount,
                minAmountOut,
                path,
                address(this),
                block.timestamp + Constants.PCS_TTL
            )
        {} catch Error(string memory reason) {
            Utils.handleErrorWhenCallingPCSSwap(state, reason);
        } catch {
            Utils.handleErrorWhenCallingPCSSwap(
                state,
                "Lowlevel err: PCS V2 sell failed"
            );
        }
    }

    function calculateMaxAmountIn(TokenConfig memory tc)
        internal
        view
        returns (uint256)
    {
        if (tc.tokenBuyLimit == 0) {
            return tc.buyAmount;
        }

        uint256 totalSupply = IERC20(tc.token).totalSupply();
        uint256 tokensAtLimit = (totalSupply * tc.tokenBuyLimit) / 10000;

        address[] memory path = generateBuyPath(tc);
        uint256[] memory amounts = IPCSV2Router(PCS_V2_ROUTER).getAmountsIn(
            tokensAtLimit,
            path
        );

        return amounts[0] > tc.buyAmount ? tc.buyAmount : amounts[0];
    }

    function generateBuyPath(TokenConfig memory tc)
        private
        pure
        returns (address[] memory path)
    {
        if (tc.liquidityToken == Constants.WBNB) {
            path = new address[](2);
            path[0] = tc.liquidityToken;
            path[1] = tc.token;
        } else {
            path = new address[](3);
            path[0] = Constants.WBNB;
            path[1] = tc.liquidityToken;
            path[2] = tc.token;
        }
    }
}
