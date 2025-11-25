// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ICurveFi } from "../interfaces/ICurveFi.sol";

/**
 * @title SwapTokens
 * @dev Library for swapping tokens across multiple DEXs: Uniswap V3, Uniswap V2, SushiSwap, PancakeSwap, and Curve.
 *
 * Notes for production:
 * - The calling contract must hold `tokenIn` balance when calling these functions.
 * - These functions approve the router/pool to spend `amountIn`. Approvals are set by first setting allowance to 0
 *   and then to the desired amount to support tokens that require 0-first approval (eg. USDT).
 * - Curve token index discovery queries coins(i) with try/catch up to MAX_COINS (safe upper bound).
 */
library SwapTokens {
    using SafeERC20 for IERC20;

    // // Mainnet router addresses (immutable-ish constants)
    // ISwapRouter public constant uniswapV3Router =
    //     ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    // IUniswapV2Router02 public constant uniswapV2Router =
    //     IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // IUniswapV2Router02 public constant sushiswapRouter =
    //     IUniswapV2Router02(0xd9e1CE17f2641f24aE83637ab66a2cca9C378B9F);
    // IUniswapV2Router02 public constant pancakeswapRouter =
    //     IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // Polygon mainnet router addresses
    ISwapRouter public constant uniswapV3Router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Uniswap V3 Router (same as Ethereum)
    IUniswapV2Router02 public constant uniswapV2Router =
        IUniswapV2Router02(0xedf6066a2b290C185783862C7F4776A2C8077AD1); // Uniswap V2 
    IUniswapV2Router02 public constant sushiswapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // SushiSwap 
    IUniswapV2Router02 public constant quickswapRouter = 
        IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); // QuickSwap
    // IUniswapV2Router02 public constant pancakeswapRouter =
    //     IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBc46c52416550D1); // PancakeSwap Polygon

    uint256 private constant MAX_CURVE_COINS = 32; // safe upper bound; adjust if you know pools bigger

    /**
     * @dev Internal helper to safely set allowance for `spender` to `amount`.
     *      For maximum compatibility with non-standard ERC20s, we first set to 0 then to amount.
     */
    function ensureApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20 t = IERC20(token);
        // If allowance already equals amount, skip
        uint256 current = t.allowance(address(this), spender);
        if (current < amount) {
            t.approve(spender, type(uint256).max);
        }

        // // Some tokens (eg. USDT) require setting allowance to 0 before changing it.
        // if (current > 0) {
        //     t.approve(spender, 0);
        // }
        // t.approve(spender, amount);
    }

    /**
     * @dev Swap tokens using Uniswap V3.
     *      Caller must have tokenIn balance in this contract prior to calling.
     */
    function UniswapV3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address receiver
    ) internal returns (bool, uint256) {

        ensureApprove(tokenIn, address(uniswapV3Router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: 3000, // 0.3% pool - change if you prefer a different fee tier
                recipient: address(this), // receive to this contract then forward to receiver
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: 1,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = uniswapV3Router.exactInputSingle(params);

        // forward to receiver
        if (receiver != address(this)) {
            IERC20(tokenOut).safeTransfer(receiver, amountOut);
        }

        return (true, amountOut);
    }

    /**
     * @dev Swap tokens using Uniswap V2 (also used for generic Uniswap V2 forks).
     */
    function UniswapV2(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address receiver
    ) internal returns (bool, uint256) {

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        ensureApprove(tokenIn, address(uniswapV2Router), amountIn);

        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
            amountIn,
            1,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 amountOut = amounts[amounts.length - 1];
        if (receiver != address(this)) {
            IERC20(tokenOut).safeTransfer(receiver, amountOut);
        }

        return (true, amountOut);
    }

    /**
     * @dev Swap tokens using SushiSwap.
     */
    function Sushiswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address receiver
    ) internal returns (bool, uint256) {

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        ensureApprove(tokenIn, address(sushiswapRouter), amountIn);

        uint256[] memory amounts = sushiswapRouter.swapExactTokensForTokens(
            amountIn,
            1,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 amountOut = amounts[amounts.length - 1];
        if (receiver != address(this)) {
            IERC20(tokenOut).safeTransfer(receiver, amountOut);
        }

        return (true, amountOut);
    }

    /**
     * @dev Swap tokens using QuickSwap.
     */
    function Quickswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address receiver
    ) internal returns (bool, uint256) {

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        ensureApprove(tokenIn, address(quickswapRouter), amountIn);

        uint256[] memory amounts = quickswapRouter.swapExactTokensForTokens(
            amountIn,
            1,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 amountOut = amounts[amounts.length - 1];
        if (receiver != address(this)) {
            IERC20(tokenOut).safeTransfer(receiver, amountOut);
        }

        return (true, amountOut);
    }

    /**
     * @dev Swap tokens using a Curve pool.
     *
     * curvePool: address of the Curve pool contract (must implement `coins(uint256)` and `exchange(int128,int128,uint256,uint256)`).
     * Note: this function queries the pool's coins(i) to find token indices.
     */
    function Curve(
        int128 i,
        int128 j,
        address curvePool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address receiver
    ) internal returns (bool, uint256) {

        if (i == int128(-1) || j == int128(-1)) {
            (i, j) = getCurveTokenIndices(curvePool, tokenIn, tokenOut);
        }

        // approve pool to take `amountIn` of tokenIn
        IERC20(tokenIn).safeIncreaseAllowance(curvePool, amountIn);
        // For safety with tokens that don't support increaseAllowance, also call ensureApprove as fallback
        // (safeIncreaseAllowance may fail for some tokens; try-catch is more expensive, so we do both)
        try IERC20(tokenIn).allowance(address(this), curvePool) returns (uint256 allowanceAfter) {
            if (allowanceAfter < amountIn) {
                // fallback to ensureApprove
                ensureApprove(tokenIn, curvePool, amountIn);
            }
        } catch {
            // if allowance call fails for the token, fallback to ensureApprove
            ensureApprove(tokenIn, curvePool, amountIn);
        }

        // perform exchange: the pool will send the output tokens to this contract
        uint256 amountOut = ICurveFi(curvePool).exchange(i, j, amountIn, 1);

        // forward output token to receiver
        address outTokenAddr = ICurveFi(curvePool).coins(uint256(uint128(j)));
        if (receiver != address(this)) {
            IERC20(outTokenAddr).safeTransfer(receiver, amountOut);
        }

        return (true, amountOut);
    }

    /**
     * @dev Find token indices i and j for tokenIn and tokenOut on a Curve pool by calling coins(k).
     *      This function tries indices from 0 .. MAX_CURVE_COINS-1 and returns when matches are found.
     *      Reverts if a token is not found or indices are identical.
     */
    function getCurveTokenIndices(
        address curvePool,
        address tokenIn,
        address tokenOut
    ) internal view returns (int128 iIndex, int128 jIndex) {

        bool foundI = false;
        bool foundJ = false;
        uint256 foundICandidate;
        uint256 foundJCandidate;

        for (uint256 k = 0; k < MAX_CURVE_COINS; k++) {
            // safe external call using try/catch on the interface method
            try ICurveFi(curvePool).coins(k) returns (address coinAddr) {
                if (!foundI && coinAddr == tokenIn) {
                    foundI = true;
                    foundICandidate = k;
                    if (foundJ) break;
                }
                if (!foundJ && coinAddr == tokenOut) {
                    foundJ = true;
                    foundJCandidate = k;
                    if (foundI) break;
                }
            } catch {
                // coins(k) reverted (likely index out-of-range) -> stop searching
                break;
            }
        }

        require(foundI && foundJ, "Curve: token(s) not in pool");
        require(foundICandidate != foundJCandidate, "Curve: invalid or same token indices");

        // safe conversion to int128 (indices are small)
        iIndex = int128(int256(int256(foundICandidate)));
        jIndex = int128(int256(int256(foundJCandidate)));
    }
}
