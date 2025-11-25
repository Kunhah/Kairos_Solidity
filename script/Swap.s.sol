// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Script, console } from "forge-std/Script.sol";
import { Swap } from "../src/Swap.sol";
import { SwapNoFee } from "../src/SwapNoFee.sol";

contract SwapScript is Script {

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy Swap contract
        Swap swap = new Swap();
        console.log("Swap deployed at:", address(swap));

        // Deploy SwapNoFee contract
        SwapNoFee swapNoFee = new SwapNoFee();
        console.log("SwapNoFee deployed at:", address(swapNoFee));

        vm.stopBroadcast();
    }
}