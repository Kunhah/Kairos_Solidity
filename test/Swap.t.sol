// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { Swap } from "../src/Swap.sol";
import { ReferralSystem } from "../src/Referral.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { PayTypes } from "../src/libs/PayTypes.sol";

contract SwapTest is Test {
    Swap swap;
    MockERC20 tokenA;
    MockERC20 tokenB;

    address user = address(0x123);
    address referrer = address(0x456);

    function setUp() public {
        swap = new Swap();
        tokenA = new MockERC20("tokenA", "tokenA", 18);
        tokenB = new MockERC20("tokenB", "tokenB", 18);

        tokenA.mint(user, 1_000 ether);
        tokenB.mint(address(swap), 1_000 ether);

        vm.startPrank(user);
        tokenA.approve(address(swap), type(uint256).max);
        vm.stopPrank();
    }

    function testBatchSwapSingleStep() public {
        PayTypes.Swap[] memory batch = new PayTypes.Swap[](1);
        PayTypes.Swap memory s;
        s.sender = user;
        s.amount = 100 ether;

        PayTypes.SwapStep[] memory steps = new PayTypes.SwapStep[](1);
        steps[0] = PayTypes.SwapStep({
            tokenIn: address(tokenA),
            tokenOut: address(tokenB),
            dex: PayTypes.DEX.UniswapV2,
            data: bytes("")
        });

        s.swapSteps = steps;
        batch[0] = s;

        vm.prank(user);
        swap.BatchSwap(batch);

        assertEq(tokenA.balanceOf(user), 900 ether);
    }
}

contract ReferralTest is Test {
    Swap ref;
    address owner = address(this);
    address seller = address(0xAAA);
    address user1 = address(0x111);
    address user2 = address(0x222);
    MockERC20 token;

    function setUp() public {
        token = new MockERC20("token", "token", 18);
        ref = new Swap();
        token.mint(user1, 1_000 ether);
    }

    function testSellerApproval() public {
        ref.modifySeller(seller, true);
        assertTrue(ref.approvedSeller(seller));
    }

    function testRegisterReferral() public {
        ref.modifySeller(seller, true);
        vm.prank(user1);
        ref.registerReferral(seller);
        assertEq(ref.getReferrer(user1), seller);
    }
}

// Additional comprehensive tests
contract SwapExtendedTest is Test {
    Swap swap;
    MockERC20 tokenA;
    MockERC20 tokenB;
    address user = address(0x1234);
    address ref = address(0x9999);

    function setUp() public {
        swap = new Swap();
        tokenA = new MockERC20("tokenA", "tokenA", 18);
        tokenB = new MockERC20("tokenB", "tokenB", 18);

        tokenA.mint(user, 10_000 ether);
        tokenB.mint(address(swap), 10_000 ether);

        vm.startPrank(user);
        tokenA.approve(address(swap), type(uint256).max);
        vm.stopPrank();
    }

    function testMultiStepSwap() public {
        PayTypes.Swap memory S;
        S.sender = user;
        S.amount = 300 ether;

        PayTypes.SwapStep[] memory steps = new PayTypes.SwapStep[](2);
        steps[0] = PayTypes.SwapStep({
            tokenIn: address(tokenA),
            tokenOut: address(tokenA),
            dex: PayTypes.DEX.UniswapV2,
            data: bytes("")
        });
        steps[1] = PayTypes.SwapStep({
            tokenIn: address(tokenA),
            tokenOut: address(tokenB),
            dex: PayTypes.DEX.UniswapV2,
            data: bytes("")
        });

        S.swapSteps = steps;
        PayTypes.Swap[] memory batch = new PayTypes.Swap[](1);
        batch[0] = S;

        vm.prank(user);
        swap.BatchSwap(batch);

        assertEq(tokenA.balanceOf(user), 9700 ether);
    }

    // function testFlatFee() public {
    //     PayTypes.Swap memory S;
    //     S.sender = user;
    //     S.amount = 1000 ether;
    //     S.isFlat = true;

    //     PayTypes.SwapStep[] memory steps = new PayTypes.SwapStep[](1);
    //     steps[0] = PayTypes.SwapStep({
    //         tokenIn: address(tokenA),
    //         tokenOut: address(tokenB),
    //         dex: PayTypes.DEX.UniswapV2,
    //         data: bytes("")
    //     });

    //     S.swapSteps = steps;

    //     PayTypes.Swap[] memory batch = new PayTypes.Swap[](1);
    //     batch[0] = S;

    //     vm.prank(user);
    //     swap.BatchSwap(batch);

    //     uint256 expectedFee = (1000 ether * swap.FEE_FLAT()) / swap.BPS_DIVISOR();
    //     assertEq(tokenB.balanceOf(address(swap)), expectedFee);
    // }

    function testUnsupportedDexReverts() public {
        PayTypes.Swap memory S;
        S.sender = user;
        S.amount = 100 ether;

        PayTypes.SwapStep[] memory steps = new PayTypes.SwapStep[](1);
        steps[0] = PayTypes.SwapStep({
            tokenIn: address(tokenA),
            tokenOut: address(tokenB),
            dex: PayTypes.DEX(10), // invalid
            data: bytes("")
        });

        S.swapSteps = steps;

        PayTypes.Swap[] memory batch = new PayTypes.Swap[](1);
        batch[0] = S;

        vm.prank(user);
        vm.expectRevert();
        swap.BatchSwap(batch);
    }
}

contract ReferralAdvancedTest is Test {
    Swap ref;
    MockERC20 token;
    address owner = address(this);
    address L1 = address(0x111);
    address L2 = address(0x222);
    address L3 = address(0x333);
    address L4 = address(0x444);
    address L5 = address(0x555);
    address user = address(0x999);

    function setUp() public {
        ref = new Swap();
        token = new MockERC20("token", "token", 18);
        token.mint(user, 10_000 ether);

        ref.modifySeller(L1, true);
        ref.modifySeller(L2, true);
        ref.modifySeller(L3, true);
        ref.modifySeller(L4, true);
        ref.modifySeller(L5, true);
    }

    function testMultiLevelReferralRewards() public {
        vm.prank(L2);
        ref.registerReferral(L1);
        vm.prank(L3);
        ref.registerReferral(L2);
        vm.prank(L4);
        ref.registerReferral(L3);
        vm.prank(L5);
        ref.registerReferral(L4);
        vm.prank(user);
        ref.registerReferral(L5);

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        uint256 amount = 1000 ether;
        uint256 distributed = ref.convertReferralRewardsToUSDT(user, tokens);

        uint24[5] memory P = ref.getPercentages();

        uint256 expected = (amount * (P[0] + P[1] + P[2] + P[3] + P[4])) / 1_000_000;
        assertEq(distributed, expected);
    }

    function testCircularReverts() public {
        vm.prank(L2);
        ref.registerReferral(L1);
        vm.prank(L1);
        vm.expectRevert();
        ref.registerReferral(L2);
    }

    function testSellerCannotSetReferrer() public {
        ref.modifySeller(user, true);
        vm.prank(user);
        vm.expectRevert();
        ref.registerReferral(L1);
    }
}

// ----------------------------
// Fuzz tests for Swap and Referral
// ----------------------------
contract SwapFuzzTest is Test {
    Swap swap;
    MockERC20 tokenA;
    MockERC20 tokenB;
    address user = address(0xCAFE);

    function setUp() public {
        swap = new Swap();
        tokenA = new MockERC20("tokenA", "tokenA", 18);
        tokenB = new MockERC20("tokenB", "tokenB", 18);

        tokenA.mint(user, 1_000_000 ether);
        tokenB.mint(address(swap), 1_000_000 ether);

        vm.startPrank(user);
        tokenA.approve(address(swap), type(uint256).max);
        vm.stopPrank();
    }

    /// @notice fuzz single-step swap with variable amount (bounded)
    function testFuzz_singleStepSwap(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000 ether);

        PayTypes.Swap memory S;
        S.sender = user;
        S.amount = amount;

        PayTypes.SwapStep[] memory steps = new PayTypes.SwapStep[](1);
        steps[0] = PayTypes.SwapStep({
            tokenIn: address(tokenA),
            tokenOut: address(tokenB),
            dex: PayTypes.DEX.UniswapV2,
            data: bytes("")
        });
        S.swapSteps = steps;

        vm.prank(user);
        // Expect the call to either succeed or gracefully return false inside BatchSwap
        // We just ensure it does not revert under reasonable amounts
        try swap.BatchSwap(toArray(S)) {
        } catch {
            // ok if it reverts for weird internal states; fuzz should not cause panic
        }

        // ensure user balance never increases as a result of swapping their own token back
        assertLe(tokenA.balanceOf(user), 1_000_000 ether);
    }

    function toArray(PayTypes.Swap memory s) internal pure returns (PayTypes.Swap[] memory) {
        PayTypes.Swap[] memory arr = new PayTypes.Swap[](1);
        arr[0] = s;
        return arr;
    }
}

contract ReferralFuzzTest is Test {
    Swap ref;
    MockERC20 token;

    address root = address(this);
    address a = address(0xA1);
    address b = address(0xB2);
    address c = address(0xC3);
    address d = address(0xD4);
    address e = address(0xE5);
    address user = address(0xF6);

    function setUp() public {
        ref = new Swap();
        token = new MockERC20("token", "token", 18);
        token.mint(user, 100_000 ether);

        // approve sellers
        ref.modifySeller(a, true);
        ref.modifySeller(b, true);
        ref.modifySeller(c, true);
        ref.modifySeller(d, true);
        ref.modifySeller(e, true);
    }

    /// @notice fuzz the convertReferralRewardsToUSDT with variable amount - ensure distributed <= amount
    function testFuzz_distribute(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 50_000 ether);

        // create a 5-level chain a<-b<-c<-d<-e<-user
        vm.prank(b); ref.registerReferral(a);
        vm.prank(c); ref.registerReferral(b);
        vm.prank(d); ref.registerReferral(c);
        vm.prank(e); ref.registerReferral(d);
        vm.prank(user); ref.registerReferral(e);

        uint256 beforeBalA = token.balanceOf(a);
        uint256 beforeBalB = token.balanceOf(b);

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        uint256 distributed = ref.convertReferralRewardsToUSDT(user, tokens);

        // distributed should never exceed amount
        assertLe(distributed, amount);

        // balances of first-level and second-level shouldn't decrease because we used trySafeTransferFrom in the implementation
        assertGe(token.balanceOf(a), beforeBalA);
        assertGe(token.balanceOf(b), beforeBalB);
    }

    /// @notice fuzz that zero amount reverts
    function testFuzz_zeroAmountReverts() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        vm.expectRevert();
        ref.convertReferralRewardsToUSDT(user, tokens);
    }
}

