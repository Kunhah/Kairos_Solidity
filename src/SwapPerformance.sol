// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { SwapTokens } from "./libs/SwapTokens.sol";
import { ISwap } from "./interfaces/ISwap.sol";
import { PayTypes } from "./libs/PayTypes.sol";
import { AggregatorV3Interface } from "./interfaces/AggregatorV3Interface.sol";
import { ReferralSystem } from "./Referral.sol";

contract SwapPerformance is ISwap, ReferralSystem {
    using SafeERC20 for IERC20;

    address public constant ProtocolAddress = address(0x0000000000000000000000000000000000000000);

    uint256 public constant FEE_BPS = 97_000; // 0.97%
    uint256 public constant FEE_FLAT = 970; // 0.097%
    uint256 public constant BPS_DIVISOR = 1_000_000;

    mapping(address => mapping(address => uint256)) unclaimedFee; // user => token => amount

    /**
    * @dev Constructor
    */
    constructor() {}

    /**
    * @dev Makes swaps in batch
    * @param swaps The swaps, they are divided in tokenIn, tokenOut, sender, amount, and dex
    * @notice tokenIn The token address that will be inputed for the payment
    * @notice tokensOut The token address that will be outputed for the payment
    * @notice sender The address that will swap
    * @notice dex The descentralized exchange that will be used for the swap
    * @notice amounts The amount that will be paid
    */
    function BatchSwap(PayTypes.Swap[] calldata swaps) public {
        bool[] memory success = new bool[](swaps.length);
        for (uint256 i = 0; i < swaps.length; i++) {

            bool _success = _Swap(swaps[i], swaps[i].amount);
            success[i] = _success;
        }
        emit PayTypes.BatchSwap(swaps, success);
    }

    /**
    * @dev This function swaps and transfer to the address, or simply transfer if the tokens are the same
    * @param swap The transaction, they are divided in tokenIn, tokenOut, sender, receiver, ande dex
    * @notice tokenIn The token address that will be inputed for the payment
    * @notice tokensOut The token address that will be outputed for the payment
    * @notice sender The senders of the payment
    * @notice receiver The receivers of the payment
    * @notice dex The descentralized exchange that will be used for the swap
    * @notice amount The amount of tokens to transfer
    */
    function _Swap(PayTypes.Swap calldata swap, uint256 amount) internal returns(bool) {

        AggregatorV3Interface aggregatorIn = PolygonChainlink.getPriceFeedAddress(PolygonChainlink.ADDRESS_USDC, swap.swapSteps[0].tokenIn);
        uint256 usdValueBefore = swap.swapSteps[0].tokenIn.balanceOf(swap.sender) * aggregatorIn.latestRoundData();

        //uint256 fee = (amount * FEE_FLAT) / BPS_DIVISOR;

        if (swap.swapSteps.length == 1) {
            bool success = IERC20(swap.swapSteps[0].tokenIn).trySafeTransferFrom(swap.sender, address(this), amount);
            if (!success) {
                return false;
            }
            (success, ) = _SwapTokens(swap.swapSteps[0].tokenIn, swap.swapSteps[0].tokenOut, amount, swap.sender, swap.swapSteps[0].dex, swap.swapSteps[0].data);
            if (!success) {
                bool __transferSuccess = IERC20(swap.swapSteps[0].tokenIn).trySafeTransferFrom(address(this), swap.sender, amount);
                if (!__transferSuccess) {
                    IERC20(swap.swapSteps[0].tokenIn).safeTransferFrom(address(this), ProtocolAddress, amount);
                    emit PayTypes.ProtocolReceived(amount, swap.sender, swap.swapSteps[0].tokenIn);
                    return false;
                }
                return false;
            }
            else {
                uint256 gain = tokenOut.balanceOf(swap.sender) - balanceBefore;
                uint256 fee = gain * FEE_BPS / BPS_DIVISOR;
                uint256 balance = IERC20(swap.swapSteps[0].tokenIn).balanceOf(address(this));
                bool _transferSuccess = IERC20(swap.swapSteps[0].tokenIn).trySafeTransferFrom(address(this), swap.sender, balance);
                if (!_transferSuccess) {
                    IERC20(swap.swapSteps[0].tokenIn).safeTransferFrom(address(this), ProtocolAddress, balance);
                    emit PayTypes.ProtocolReceived(amount, swap.sender, swap.swapSteps[0].tokenIn);
                    return false;
                }

                
            }
        } else {
            bool success = IERC20(swap.swapSteps[0].tokenIn).trySafeTransferFrom(swap.sender, address(this), amount);
            if (!success) {
                return false;
            }
            uint256 amountIn = amount;
            uint256 amountOut;
            for (uint256 i = 0; i < swap.swapSteps.length; ++i) {   
                (success, amountOut) = _SwapTokens(swap.swapSteps[i].tokenIn, swap.swapSteps[i].tokenOut, amountIn, i == swap.swapSteps.length - 1 ? swap.sender : address(this), swap.swapSteps[i].dex, swap.swapSteps[i].data);
                if (!success) {
                    bool __transferSuccess = IERC20(swap.swapSteps[i].tokenIn).trySafeTransferFrom(address(this), swap.sender, amountIn);
                    if (!__transferSuccess) {
                        IERC20(swap.swapSteps[i].tokenIn).safeTransferFrom(address(this), ProtocolAddress, amountIn);
                        emit PayTypes.ProtocolReceived(amount, swap.sender, swap.swapSteps[0].tokenIn);
                        return false;
                    }
                    return false;
                }
                else {
                    amountIn = amountOut;
                    uint256 balance = IERC20(swap.swapSteps[i].tokenIn).balanceOf(address(this));
                    bool _transferSuccess = IERC20(swap.swapSteps[i].tokenIn).trySafeTransferFrom(address(this), swap.sender, balance);
                    if (!_transferSuccess) {
                        IERC20(swap.swapSteps[i].tokenIn).safeTransferFrom(address(this), ProtocolAddress, balance);
                        emit PayTypes.ProtocolReceived(amount, swap.sender, swap.swapSteps[0].tokenIn);
                        return false;
                    }
                }
            }

            AggregatorV3Interface aggregatorOut = PolygonChainlink.getPriceFeedAddress(PolygonChainlink.ADDRESS_USDC, swap.swapSteps[swap.swapSteps.length - 1].tokenOut);
            uint256 usdValueAfter = swap.swapSteps[swap.swapSteps.length - 1].tokenOut.balanceOf(swap.sender) * aggregatorOut.latestRoundData();

            uint256 fee = ((usdValueAfter - usdValueBefore) * FEE_BPS / BPS_DIVISOR) / aggregatorOut.latestRoundData(); // CONVERSION IS NEEDED

            uint256 distributedAmount = distributeReferralRewards(ProtocolAddress, tokenOut,)

            swap.swapSteps[swap.swapSteps.length - 1].tokenOut.safeTransferFrom(swap.sender, ProtocolAddress, fee - distributedAmount);

            return true;
        }
    }

    /**
    * @notice Swaps `amountIn` of `tokenIn` for `tokenOut` using Uniswap V3 and sends to `receiver`.
    * @dev Uses `exactInputSingle` for single-hop swaps. Assumes tokens are already transferred to this contract.
    * @param tokenIn The address of the input ERC20 token.
    * @param tokenOut The address of the output ERC20 token.
    * @param amountIn The amount of input tokens to swap.
    * @param receiver The recipient address for the output tokens.
    */
    function _SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, address receiver, PayTypes.DEX dex, bytes calldata extraData) internal returns(bool success, uint256 result) {

        if (dex == PayTypes.DEX.UniswapV3) {
            return SwapTokens.UniswapV3(tokenIn, tokenOut, amountIn, receiver);
        }
        else if (dex == PayTypes.DEX.UniswapV2) {
            return SwapTokens.UniswapV2(tokenIn, tokenOut, amountIn, receiver);
        }
        else if (dex == PayTypes.DEX.Sushiswap) {
            return SwapTokens.Sushiswap(tokenIn, tokenOut, amountIn, receiver);
        }
        else if (dex == PayTypes.DEX.Pancakeswap) {
            return SwapTokens.Pancakeswap(tokenIn, tokenOut, amountIn, receiver);
        }
        else if (dex == PayTypes.DEX.Curve) {
            address pool = abi.decode(extraData, (address));
            return SwapTokens.Curve(pool, tokenIn, tokenOut, amountIn, receiver);
        }
        else {
            revert PayTypes.UnsupportedDEX(dex);
        }
    }
}