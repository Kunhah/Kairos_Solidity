// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { PoolId, PoolIdLibrary } from "@uniswap/v4-core/src/types/PoolId.sol";
import { IHooks } from "@uniswap/v4-core/src/interfaces/IHooks.sol";

contract UniswapV4TWAPOracle {
    using PoolIdLibrary for PoolKey;
    
    IPoolManager public immutable poolManager;
    
    // Custom storage for pool states since getSlot0 is not available
    struct PoolState {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        bool initialized;
    }
    
    struct Observation {
        uint32 timestamp;
        int56 tickCumulative;
        uint160 sqrtPriceX96;
        bool initialized;
    }
    
    mapping(PoolId => PoolState) public poolStates;
    mapping(PoolId => Observation[]) public observations;
    
    event PoolStateUpdated(PoolId poolId, uint160 sqrtPriceX96, int24 tick);
    event ObservationRecorded(PoolId poolId, uint256 price, uint32 timestamp);
    
    constructor(address _poolManager) {
        poolManager = IPoolManager(_poolManager);
    }
    
    /**
     * @dev Update pool state - this needs to be called when pool state changes
     * In production, this would be called by a hook or through pool interactions
     */
    function updatePoolState(
        PoolKey memory key,
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext
    ) external {
        PoolId poolId = key.toId();
        
        poolStates[poolId] = PoolState({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: observationIndex,
            observationCardinality: observationCardinality,
            observationCardinalityNext: observationCardinalityNext,
            initialized: true
        });
        
        // Record observation
        _recordObservation(poolId, sqrtPriceX96, tick);
        
        emit PoolStateUpdated(poolId, sqrtPriceX96, tick);
    }
    
    /**
     * @dev Record observation for TWAP calculation
     */
    function _recordObservation(PoolId poolId, uint160 sqrtPriceX96, int24 tick) internal {
        Observation memory newObservation = Observation({
            timestamp: uint32(block.timestamp),
            tickCumulative: 0, // We'd need to track this cumulatively
            sqrtPriceX96: sqrtPriceX96,
            initialized: true
        });
        
        observations[poolId].push(newObservation);
        
        uint256 price = _sqrtPriceX96ToPrice(sqrtPriceX96, poolId);
        emit ObservationRecorded(poolId, price, uint32(block.timestamp));
    }
    
    /**
     * @dev Get current price from stored pool state
     */
    function getCurrentPrice(PoolKey memory key) public view returns (uint256 price) {
        PoolId poolId = key.toId();
        PoolState memory state = poolStates[poolId];
        require(state.initialized, "Pool state not initialized");
        
        return _sqrtPriceX96ToPrice(state.sqrtPriceX96, poolId);
    }
    
    /**
     * @dev Calculate TWAP using recorded observations
     */
    function getTWAP(
        PoolKey memory key,
        uint32 twapInterval
    ) public view returns (uint256 price) {
        PoolId poolId = key.toId();
        Observation[] storage poolObservations = observations[poolId];
        require(poolObservations.length >= 2, "Insufficient observations");
        
        uint32 targetTimestamp = uint32(block.timestamp) - twapInterval;
        
        // Find observations that bracket the target time
        (Observation memory beforeOrAt, Observation memory atOrAfter) = 
            _getSurroundingObservations(poolObservations, targetTimestamp);
        
        if (beforeOrAt.timestamp == atOrAfter.timestamp) {
            price = _sqrtPriceX96ToPrice(beforeOrAt.sqrtPriceX96, poolId);
        } else {
            // Calculate time-weighted average price
            uint32 timeWeight = atOrAfter.timestamp - beforeOrAt.timestamp;
            uint32 timeBeforeTarget = targetTimestamp - beforeOrAt.timestamp;
            uint32 timeAfterTarget = atOrAfter.timestamp - targetTimestamp;
            
            uint256 priceBefore = _sqrtPriceX96ToPrice(beforeOrAt.sqrtPriceX96, poolId);
            uint256 priceAfter = _sqrtPriceX96ToPrice(atOrAfter.sqrtPriceX96, poolId);
            
            // Time-weighted average
            price = (priceBefore * timeAfterTarget + priceAfter * timeBeforeTarget) / timeWeight;
        }
        
        return price;
    }
    
    /**
     * @dev Get surrounding observations for a target timestamp
     */
    function _getSurroundingObservations(
        Observation[] storage observationsArray,
        uint32 targetTimestamp
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        for (uint256 i = 0; i < observationsArray.length; i++) {
            if (observationsArray[i].timestamp >= targetTimestamp) {
                if (i == 0) {
                    atOrAfter = observationsArray[0];
                    beforeOrAt = atOrAfter;
                } else {
                    atOrAfter = observationsArray[i];
                    beforeOrAt = observationsArray[i - 1];
                }
                break;
            }
        }
        
        if (atOrAfter.timestamp == 0) {
            beforeOrAt = observationsArray[observationsArray.length - 1];
            atOrAfter = beforeOrAt;
        }
        
        require(beforeOrAt.initialized && atOrAfter.initialized, "Invalid observations");
        return (beforeOrAt, atOrAfter);
    }
    
    /**
     * @dev Convert sqrtPriceX96 to actual price
     */
    function _sqrtPriceX96ToPrice(uint160 sqrtPriceX96, PoolId poolId) internal pure returns (uint256 price) {
        uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        price = (priceX96 * 1e18) >> (96 * 2);
    }
    
    /**
     * @dev Get number of observations for a pool
     */
    function getObservationCount(PoolKey memory key) public view returns (uint256) {
        return observations[key.toId()].length;
    }
    
    /**
     * @dev Manually record observation (for external calls)
     */
    function recordObservation(PoolKey memory key) external returns (uint256 price) {
        PoolId poolId = key.toId();
        PoolState memory state = poolStates[poolId];
        require(state.initialized, "Pool state not initialized");
        
        _recordObservation(poolId, state.sqrtPriceX96, state.tick);
        return _sqrtPriceX96ToPrice(state.sqrtPriceX96, poolId);
    }

    function getPool(
        address tokenA,
        address tokenB, 
        uint24 fee
    ) public pure returns (PoolKey memory) {
        // Sort tokens
        (address token0, address token1) = tokenA < tokenB ? 
            (tokenA, tokenB) : (tokenB, tokenA);
        
        return PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: fee,
            tickSpacing: 60, // Default tick spacing for 0.3% fee
            hooks: IHooks(address(0))
        });
    }

    /**
     * @dev Get current sqrtPriceX96 for a pool
     * This needs to be updated via updatePoolState or hooks
     */
    function getCurrentSqrtPriceX96(PoolKey memory key) public view returns (uint160) {
        PoolId poolId = key.toId();
        PoolState memory state = poolStates[poolId];
        require(state.initialized, "Pool state not initialized");
        return state.sqrtPriceX96;
    }
    
    /**
     * @dev Get current sqrtPriceX96 for token pair (convenience method)
     */
    function getCurrentSqrtPriceX96(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (uint160) {
        PoolKey memory key = getPool(tokenA, tokenB, fee);
        return getCurrentSqrtPriceX96(key);
    }
    
}