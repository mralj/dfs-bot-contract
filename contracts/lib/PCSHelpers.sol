// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./PCSV2Helpers.sol";
import "./PCSV3Helpers.sol";
import "./PBSState.sol";

contract PCSHelpers is PBSState {
    enum PCSV {
        V2,
        V3
    }

    PCSV private _pcsVersion;
    address[4] _popularLiquidityTokens = [
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, // WBNB
        0x55d398326f99059fF775485246999027B3197955, // BSC-USD (USDT)
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, // BUSD
        0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d // USDC
    ];

    constructor(address preparer, address seller) PBSState(preparer, seller) {
        _pcsVersion = PCSV.V2;
    }

    function buyHelper() internal {
        if (_pcsVersion == PCSV.V2) {
            PCSV2Helpers.buy(state, tokenConfig);
        } else {
            PCSV3Helpers.buy(state, tokenConfig);
        }
    }

    function sellHelper() internal {
        if (_pcsVersion == PCSV.V2) {
            PCSV2Helpers.sell(state, tokenConfig);
        } else {
            PCSV3Helpers.sell(state, tokenConfig);
        }
    }

    function getLiquidityToken(address buyToken, address expectedLiquidityToken)
        internal
        returns (address)
    {
        address liquidityToken = getLiquidityToken(
            buyToken,
            expectedLiquidityToken,
            PCSV2Helpers.liquidityAdded
        );

        bool liquidityAdded = liquidityToken != address(0);
        if (liquidityAdded) {
            _pcsVersion = PCSV.V2;
            return liquidityToken;
        }

        liquidityToken = getLiquidityToken(
            buyToken,
            expectedLiquidityToken,
            PCSV3Helpers.liquidityAdded
        );

        liquidityAdded = liquidityToken != address(0);
        if (liquidityAdded) {
            _pcsVersion = PCSV.V3;
        }

        return liquidityToken;
    }

    function checkIfLiqudityWasAlreadyAdded(
        address buyToken,
        address expectedLiquidityToken
    ) internal view returns (bool) {
        return
            getLiquidityToken(
                buyToken,
                expectedLiquidityToken,
                PCSV2Helpers.liquidityAdded
            ) !=
            address(0) ||
            getLiquidityToken(
                buyToken,
                expectedLiquidityToken,
                PCSV3Helpers.liquidityAdded
            ) !=
            address(0);
    }

    function getLiquidityToken(
        address buyToken,
        address expectedLiquidityToken,
        function(address, address) internal view returns (bool) liquidityAdded
    ) private view returns (address) {
        if (liquidityAdded(buyToken, expectedLiquidityToken)) {
            return expectedLiquidityToken;
        }

        for (uint256 i = 0; i < _popularLiquidityTokens.length; i++) {
            if (liquidityAdded(buyToken, _popularLiquidityTokens[i])) {
                return _popularLiquidityTokens[i];
            }
        }

        return address(0);
    }

    function calculateMaxAmountIn(TokenConfig memory tc)
        internal
        view
        returns (uint256)
    {
        if (tc.tokenBuyLimit == 0) {
            return tc.buyAmount;
        }

        return
            _pcsVersion == PCSV.V2
                ? PCSV2Helpers.calculateMaxAmountIn(tc)
                : PCSV3Helpers.calculateMaxAmountIn(tc);
    }
}
