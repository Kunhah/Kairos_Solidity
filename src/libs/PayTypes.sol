// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library PayTypes {

    struct Transaction {
        SwapStep[] swapSteps;
        address sender;
        address receiver;
        uint256 amount;
    }

    struct Swap {
        SwapStep[] swapSteps;
        address sender;
        uint256 amount;
    }

    struct SwapStep {
        address tokenIn;
        address tokenOut;
        DEX dex;
        bytes data;
    }

    struct Payment {
        address tokenOut;
        uint96 readyTimestamp;
        address receiver;
        uint96 percentage;
    }

    struct MakePayment {
        SwapStep[] swapSteps;
    }

    struct PermitData {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum DEX {
        UniswapV2,
        UniswapV3,
        Sushiswap,
        Pancakeswap,
        Curve,
        Balancer,
        dYdX,
        ONEinch,
        Compound,
        Aave,
        mStable,
        GMX,
        BinanceDex,
        HuobiDex
    }

    //event Batch(bytes32 hash, uint256 nonce);

    event BatchTransaction(Transaction[] transactions, uint256 indexed nonce, bool[] success);

    event BatchSwap(Swap[] swaps, bool[] success);

    //event TransferOrSwapSuccess(address tokenIn, address tokenOut, address sender, address receiver, uint256 amount, bool swap, uint256 nonce);

    //event TransferOrSwapFailure(address tokenIn, address tokenOut, address sender, address receiver, uint256 amount, bool swap, uint256 nonce);

    event InvalidSigner(address signer, address sender);

    event ExpiredSignature(uint256 deadline, uint256 now);

    event PermitIsNotEnough(uint256 amount, uint256 permitAmount);

    event ProtocolReceived(uint256 amount, address sender, address tokenIn);

    //event LowLevelCallSuccess(address to, bytes data, bytes returnData);

    //event LowLevelCallFailure(address to, bytes data);

    error UnsupportedDEX(DEX dex);

    error InvalidLength(uint256 length_1, uint256 length_2);

    error InvalidLength3(uint256 length_1, uint256 length_2, uint256 length_3);

    error MakePaymentsIsNotReady(uint96 readyTimestamp, uint256 block_timestamp);
}
