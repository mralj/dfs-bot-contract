// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
//NOTE: needed to encode path for swap
pragma abicoder v2;

import "../external/IWBNB.sol";
import "../external/pcsv3/IPCSV3Factory.sol";
import "../external/pcsv3/IPCSV3Pool.sol";
import "../external/pcsv3/IPCSV3Router.sol";

import "./Constants.sol";
import "./Utils.sol";
import "./Types.sol";

library PCSV3Helpers {
    address constant PCS_V3_FACTORY =
        0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;

    address constant PCS_V3_ROUTER = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;

    function liquidityAdded(address token0, address token1)
        internal
        view
        returns (bool)
    {
        address[4] memory pools = getAllPoolsForTokenPair(token0, token1);

        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i] == address(0)) {
                continue;
            }

            IPCSV3Pool pool = IPCSV3Pool(pools[i]);
            if (pool.liquidity() > 0) {
                return true;
            }
        }

        return false;
    }

    //NOTE: Pool with most liqudity will offer more "stable" price and stable swaps
    // We can also use this function to perform swaps between stablecoins
    // As per PCS blogpost: https://blog.pancakeswap.finance/articles/introducing-pancake-swap-v3-a-more-efficient-and-user-friendly-dex-on-bnb-chain-and-ethereum
    // In PancakeSwap V3: when "Twinkle" trades 1000 USDT for USDC, if the most popular trading fee tier is 0.01% (as is the case for most stable pairs), then only 0.1 USDT is charged as the trading fee.
    // The amount of USDC T received by Twinkle will be 999.9.
    // Trading Fees 0.01%: For assets such as stable pairs, where prices are expected to match, the impermanent loss is low, and traders and LPs typically agree on the lowest fee tiers.
    // This is the example of USDT/USDC above.
    function getPoolWithMostLiqudity(address token0, address token1)
        private
        view
        returns (address)
    {
        uint256 maxLiquidity = 0;
        address maxLiquidityPool = address(0);
        address[4] memory pools = getAllPoolsForTokenPair(token0, token1);

        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i] == address(0)) {
                continue;
            }

            IPCSV3Pool pool = IPCSV3Pool(pools[i]);
            if (pool.liquidity() > maxLiquidity) {
                maxLiquidity = pool.liquidity();
                maxLiquidityPool = pools[i];
            }
        }

        return maxLiquidityPool;
    }

    function getAllPoolsForTokenPair(address token0, address token1)
        private
        view
        returns (address[4] memory)
    {
        //NOTE: in PCS V3 we can have different possible pools fees, we can think of this as different pools
        // This is similar to V2, so mental model would be pool = PCS V2 pair,
        // But instead having just one, we have at least 1, and at most 4 (depending how liquidities were added)
        uint24[4] memory possiblePoolFees = [uint24(100), 500, 2500, 10000]; // this was C/P from PCS V3 Factory contract (NOTE uint24(100) is needed to avoid compilation error)
        address[4] memory pools;

        for (uint256 i = 0; i < possiblePoolFees.length; i++) {
            address pool = IPCSV3Factory(PCS_V3_FACTORY).getPool(
                token0,
                token1,
                possiblePoolFees[i]
            );
            pools[i] = pool;
        }

        return pools;
    }

    function buy(State storage state, TokenConfig memory tc) internal {
        Utils.approve(IERC20(Constants.WBNB), PCS_V3_ROUTER, tc.buyAmount);
        uint256 buyAmount = tc.buyAmount;

        if (state.isBadTokenTest) {
            buyAmount = Constants.BAD_TOKEN_TEST_AMT;
        }

        if (tc.liquidityToken == Constants.WBNB) {
            buyDirect(state, tc, buyAmount);
        } else {
            Utils.approve(IERC20(tc.liquidityToken), PCS_V3_ROUTER, tc.buyAmount);
            buyViaPath(state, tc, buyAmount);
        }

        if (!state.gasError) {
            //FROM PCS V3 Docs: https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/v3/smartrouterv3#contract-info
            // At the very end of all swaps via router, refundETH should be called. PancakeSwap will ensure this.
            IPCSV3Router(PCS_V3_ROUTER).refundETH();
        }
    }

    function buyDirect(
        State storage state,
        TokenConfig memory tc,
        uint256 buyAmount
    ) private {
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: tc.liquidityToken,
                tokenOut: tc.token,
                fee: IPCSV3Pool(
                    getPoolWithMostLiqudity(tc.liquidityToken, tc.token)
                ).fee(),
                recipient: address(this),
                amountIn: tc.buyAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        try
            IPCSV3Router(PCS_V3_ROUTER).exactInputSingle{
                value: buyAmount,
                gas: Utils.gasAllowance()
            }(params)
        {} catch Error(string memory reason) {
            Utils.handleErrorWhenCallingPCSSwap(state, reason);
        } catch {
            Utils.handleErrorWhenCallingPCSSwap(
                state,
                "Lowlevel err: PCS V3 direct buy failed"
            );
        }
    }

    function buyViaPath(
        State storage state,
        TokenConfig memory tc,
        uint256 buyAmount
    ) private {
        //NOTE: From UNISWAP V3 docs: path is sequence of [tokenAddress - fee - tokenAddress]
        //example: path: abi.encodePacked(WBNB, poolFee, USDC, poolFee, WETH),
        bytes memory path = abi.encodePacked(
            Constants.WBNB,
            IPCSV3Pool(
                getPoolWithMostLiqudity(Constants.WBNB, tc.liquidityToken)
            ).fee(),
            tc.liquidityToken,
            IPCSV3Pool(getPoolWithMostLiqudity(tc.liquidityToken, tc.token))
                .fee(),
            tc.token
        );

        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
            .ExactInputParams({
                path: path,
                recipient: address(this),
                amountIn: tc.buyAmount,
                amountOutMinimum: 0
            });

        try
            IPCSV3Router(PCS_V3_ROUTER).exactInput{
                value: buyAmount,
                gas: Utils.gasAllowance()
            }(params)
        {} catch Error(string memory reason) {
            Utils.handleErrorWhenCallingPCSSwap(state, reason);
        } catch {
            Utils.handleErrorWhenCallingPCSSwap(
                state,
                "Lowlevel err: PCS V3 path buy failed"
            );
        }
    }

    function sell(State storage state, TokenConfig memory tc) internal {
        uint256 sellAmount = Utils.calculateHowManyTokensToSell(state, tc);

        Utils.approve(IERC20(tc.token), PCS_V3_ROUTER, sellAmount);

        if (tc.liquidityToken == Constants.WBNB) {
            sellDirect(state, tc, sellAmount);
        } else {
            sellViaPath(state, tc, sellAmount);
        }

        if (!state.gasError) {
            //FROM PCS V3 Docs: https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/v3/smartrouterv3#contract-info
            // At the very end of all swaps via router, refundETH should be called. PancakeSwap will ensure this.
            IPCSV3Router(PCS_V3_ROUTER).refundETH();
            //TODO: we receive WNBN, so we have to unwrap it, the "todo part is" check if there is better solution
            Utils.unwrapBNB();
        }
    }

    function sellDirect(
        State storage state,
        TokenConfig memory tc,
        uint256 sellAmount
    ) private {
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: tc.token,
                tokenOut: tc.liquidityToken,
                fee: IPCSV3Pool(
                    getPoolWithMostLiqudity(tc.liquidityToken, tc.token)
                ).fee(),
                recipient: address(this),
                amountIn: sellAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        try
            IPCSV3Router(PCS_V3_ROUTER).exactInputSingle{
                gas: Utils.gasAllowance()
            }(params) //NOTE: we end up here if callee reverts and gives error as string
        {} catch Error(string memory reason) {
            Utils.handleErrorWhenCallingPCSSwap(state, reason);
        } catch {
            Utils.handleErrorWhenCallingPCSSwap(
                state,
                "Lowlevel err: PCS V3 direct sell failed"
            );
        }
    }

    function sellViaPath(
        State storage state,
        TokenConfig memory tc,
        uint256 sellAmount
    ) private {
        //NOTE: From UNISWAP V3 docs: path is sequence of [tokenAddress - fee - tokenAddress]
        //example: path: abi.encodePacked(WBNB, poolFee, USDC, poolFee, WETH),
        bytes memory path = abi.encodePacked(
            tc.token,
            IPCSV3Pool(getPoolWithMostLiqudity(tc.liquidityToken, tc.token))
                .fee(),
            tc.liquidityToken,
            IPCSV3Pool(
                getPoolWithMostLiqudity(Constants.WBNB, tc.liquidityToken)
            ).fee(),
            Constants.WBNB
        );

        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
            .ExactInputParams({
                path: path,
                recipient: address(this),
                amountIn: sellAmount,
                amountOutMinimum: 0
            });

        try
            IPCSV3Router(PCS_V3_ROUTER).exactInput{gas: Utils.gasAllowance()}(
                params
            )
        {} catch Error(string memory reason) {
            Utils.handleErrorWhenCallingPCSSwap(state, reason);
        } catch {
            Utils.handleErrorWhenCallingPCSSwap(
                state,
                "Lowlevel err: PCS V3 path sell failed"
            );
        }
    }

    //TODO: find out how to implement this properly in V3
    function calculateMaxAmountIn(TokenConfig memory tc)
        internal
        pure
        returns (uint256)
    {
        return tc.buyAmount;
    }
}
