// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Minimal interface for a Curve Finance pool
/// @notice Supports standard exchange and coin lookup functions
interface ICurveFi {
    /**
     * @notice Swap between two coins
     * @param i Index value for the coin to send
     * @param j Index value for the coin to receive
     * @param dx Amount of `i` being exchanged
     * @param min_dy Minimum amount of `j` to receive
     * @return dy Amount of `j` received
     */
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256 dy);

    /**
     * @notice Swap underlying coins (used for pools with wrapped tokens)
     * @dev Optional, not every pool supports this
     */
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256 dy);

    /**
     * @notice Get the address of a coin by index
     * @param index Coin index (0-based)
     * @return Coin ERC20 address
     */
    function coins(uint256 index) external view returns (address);

    /**
     * @notice Get the underlying coin by index (for meta-pools)
     * @dev Optional, not every pool supports this
     */
    function underlying_coins(uint256 index) external view returns (address);

    /**
     * @notice Get the number of coins in this pool (optional)
     */
    function N_COINS() external view returns (uint256);

    /**
     * @notice View function estimating output amount
     * @dev Optional, not all pools expose it
     */
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);
}
