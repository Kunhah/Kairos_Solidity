// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ICurveFi } from "./interfaces/ICurveFi.sol";

/**
* @title SwapTokens
* @dev Library for swapping tokens across multiple DEXs: Uniswap V3, Uniswap V2, SushiSwap, PancakeSwap, and Curve.
*/
library SwapTokens {
   using SafeERC20 for IERC20;

   // Mainnet router addresses
   ISwapRouter public constant uniswapV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Uniswap V3 Router ([etherscan.io](https://etherscan.io/address/0xe592427a0aece92de3edee1f18e0157c05861564))
   IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap V2 Router ([docs.uniswap.org](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02))
   IUniswapV2Router02 public constant sushiswapRouter = IUniswapV2Router02(0x0000000000000000000000000000000000000000); // SushiSwap Router ([etherscan.io](https://etherscan.io/address/0xd9e1ce17f2641f24ae83637ab66a2cca9c378b9f)) 0xd9e1CE17f2641f24aE83637ab66a2cca9C378B9F
   IUniswapV2Router02 public constant pancakeswapRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeSwap Router ([docs.pancakeswap.finance](https://docs.pancakeswap.finance/to-delete/smart-contracts/pancakeswap-exchange/v2-contracts/router-v2))
   //ICurveFi public constant curvePool = ICurveFi(0x0000000000000000000000000000000000000000); //

   /**
    * @dev Swap tokens using Uniswap V3.
    */
   function UniswapV3(
       address tokenIn,
       address tokenOut,
       uint256 amountIn,
       address receiver
   ) internal returns (bool, uint256) {
       //IERC20(tokenIn).safeIncreaseAllowance(address(uniswapV3Router), amountIn);

       ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
           tokenIn: tokenIn,
           tokenOut: tokenOut,
           fee: 3000,
           recipient: receiver,
           deadline: block.timestamp + 300,
           amountIn: amountIn,
           amountOutMinimum: 1,
           sqrtPriceLimitX96: 0
       });

       uint256 amountOut = uniswapV3Router.exactInputSingle(params);
       return (true, amountOut);
   }

   /**
    * @dev Swap tokens using Uniswap V2.
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

       //IERC20(tokenIn).safeIncreaseAllowance(address(uniswapV2Router), amountIn);

       uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
           amountIn,
           1,
           path,
           receiver,
           block.timestamp + 300
       );

       return (true, amounts[1]);
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

       //IERC20(tokenIn).safeIncreaseAllowance(address(sushiswapRouter), amountIn);
       uint256[] memory amounts = sushiswapRouter.swapExactTokensForTokens(
           amountIn,
           1,
           path,
           receiver,
           block.timestamp + 300
       );

       return (true, amounts[1]);
   }

   /**
    * @dev Swap tokens using PancakeSwap.
    */
   function Pancakeswap(
       address tokenIn,
       address tokenOut,
       uint256 amountIn,
       address receiver
   ) internal returns (bool, uint256) {
       address[] memory path = new address[](2);
       path[0] = tokenIn;
       path[1] = tokenOut;

       //IERC20(tokenIn).safeIncreaseAllowance(address(pancakeswapRouter), amountIn);
       uint256[] memory amounts = pancakeswapRouter.swapExactTokensForTokens(
           amountIn,
           1,
           path,
           receiver,
           block.timestamp + 300
       );

       return (true, amounts[1]);
   }

   /**
    * @dev Swap tokens using a Curve pool.
    */
   function Curve(
       address curvePool,
       address tokenIn,
       address tokenOut,
       uint256 amountIn,
       address receiver
   ) internal returns (bool, uint256) {
       (int128 i, int128 j) = getCurveTokenIndicesAsm(curvePool, tokenIn, tokenOut);
       IERC20(tokenIn).safeIncreaseAllowance(address(curvePool), amountIn);

       uint256 amountOut = ICurveFi(curvePool).exchange(i, j, amountIn, 1);
       IERC20(ICurveFi(curvePool).coins(uint256(uint128(j)))).safeTransfer(receiver, amountOut);

       return (true, amountOut);
   }

   function getCurveTokenIndicesAsm(address curvePool, address tokenIn, address tokenOut) internal pure returns (int128 i, int128 j) {
   assembly {

       switch curvePool
       case 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51 { // 3pool address

           switch tokenIn
           case 0xdAC17F958D2ee523a2206206994597C13D831ec7 { i := 2 } // USDT index
           case 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 { i := 1 } // USDC
           case 0x6B175474E89094C44Da98b954EedeAC495271d0F { i := 0 } // DAI

           switch tokenOut
           case 0xdAC17F958D2ee523a2206206994597C13D831ec7 { j := 2 }
           case 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 { j := 1 }
           case 0x6B175474E89094C44Da98b954EedeAC495271d0F { j := 0 }
       }


       if iszero(or(lt(i, 128), lt(j, 128))) {
           revert(0, 0)
       }
   }

   require(i != j, "Curve: invalid or same token indices");
}
}




