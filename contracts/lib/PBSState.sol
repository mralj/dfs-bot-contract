// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Types.sol";

contract PBSState is AccessControl {
    bytes32 public constant PREPARE_ROLE = keccak256("PREPARE");
    bytes32 public constant SELL_ROLE = keccak256("SELL");

    State internal state;
    TokenConfig internal tokenConfig;

    constructor(address preparer, address seller) {
        _setupRole(PREPARE_ROLE, msg.sender);
        _setupRole(PREPARE_ROLE, preparer);

        _setupRole(SELL_ROLE, msg.sender);
        _setupRole(SELL_ROLE, seller);
    }

    function resetState() internal {
        state = State(false, false, false, false, 0, 0, address(0));
    }

    function enforcePrepareInvariants() internal view {
        require(tokenConfig.buyAmount > 0, "Buy amount must be > 0");
        require(tokenConfig.sellCount > 0, "Sell count must be > 0");
        require(
            tokenConfig.testThreshold > 0 && tokenConfig.testThreshold <= 100,
            "Test Threshold must be [0, 100]"
        );
        require(
            tokenConfig.firstSellPercent > 0 &&
                tokenConfig.firstSellPercent <= 100,
            "First sell percent must be [0,100]"
        );
    }

    function enforceBuyInvariants(uint256 balance) internal view {
        require(!state.tokenBought, "Already bought token");
        require(!state.gasError, "Gas guard");
        require(!state.badToken, "Bad token");
        require(
            balance >= tokenConfig.buyAmount,
            "Not enough balance to buy token"
        );
    }

    function enforceSellInvariants() internal view {
        require(state.tokenBought, "Token not bought");
        require(state.soldCount <= tokenConfig.sellCount, "No more sells left");
    }
}
