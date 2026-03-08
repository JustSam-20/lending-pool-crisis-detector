// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "drosera-contracts/ITrap.sol";

interface IMockLendingPool {
    function getReserveLiquidity() external view returns (uint256);
    function getBorrowRate() external view returns (uint256);
    function getAverageHealthFactor() external view returns (uint256);
    function getOraclePrice() external view returns (uint256);
}

contract LendingPoolCrisisTrap is ITrap {

    address public constant MOCK_LENDING_POOL = 0x39C2C61b561F5384E74883acB442E43aCF81bb8d;

    function collect() external view override returns (bytes memory) {
        IMockLendingPool pool = IMockLendingPool(MOCK_LENDING_POOL);

        uint256 reserveLiquidity    = pool.getReserveLiquidity();
        uint256 borrowRate          = pool.getBorrowRate();
        uint256 avgHealthFactor     = pool.getAverageHealthFactor();
        uint256 oraclePrice         = pool.getOraclePrice();

        return abi.encode(
            reserveLiquidity,
            borrowRate,
            avgHealthFactor,
            oraclePrice
        );
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        // Data length guard
        if (data.length == 0 || data[0].length == 0) return (false, bytes(""));

        // Decode current block (data[0])
        (
            uint256 currentLiquidity,
            uint256 currentBorrowRate,
            uint256 currentHealthFactor,
            uint256 currentPrice
        ) = abi.decode(data[0], (uint256, uint256, uint256, uint256));

        // Decode oldest block (data[data.length - 1]) for delta comparison
        (
            uint256 oldLiquidity,
            uint256 oldBorrowRate,
            uint256 oldHealthFactor,
            uint256 oldPrice
        ) = abi.decode(data[data.length - 1], (uint256, uint256, uint256, uint256));

        uint8 triggeredVectors      = 0;
        bool reserveDrain           = false;
        bool borrowRateSpike        = false;
        bool healthFactorCollapse   = false;
        bool priceFeedDrift         = false;

        // Vector 1 — Reserve Drain Delta
        // Detects: liquidity dropped > 20% vs oldest sample
        if (oldLiquidity > 0) {
            uint256 drainThreshold = (oldLiquidity * 80) / 100;
            if (currentLiquidity < drainThreshold) {
                reserveDrain = true;
                triggeredVectors++;
            }
        }

        // Vector 2 — Borrow Rate Spike Delta
        // Detects: borrow rate jumped > 40% vs oldest sample
        if (oldBorrowRate > 0) {
            uint256 spikeThreshold = (oldBorrowRate * 140) / 100;
            if (currentBorrowRate > spikeThreshold) {
                borrowRateSpike = true;
                triggeredVectors++;
            }
        }

        // Vector 3 — Health Factor Collapse Delta
        // Detects: average health factor dropped > 15% vs oldest sample
        if (oldHealthFactor > 0) {
            uint256 collapseThreshold = (oldHealthFactor * 85) / 100;
            if (currentHealthFactor < collapseThreshold) {
                healthFactorCollapse = true;
                triggeredVectors++;
            }
        }

        // Vector 4 — Price Feed Drift Delta
        // Detects: oracle price moved > 10% in either direction vs oldest sample
        if (oldPrice > 0) {
            uint256 upperBound = (oldPrice * 110) / 100;
            uint256 lowerBound = (oldPrice * 90) / 100;
            if (currentPrice > upperBound || currentPrice < lowerBound) {
                priceFeedDrift = true;
                triggeredVectors++;
            }
        }

        // Fire if 2 or more vectors triggered
        if (triggeredVectors >= 2) {
            return (true, abi.encode(
                currentLiquidity,
                currentBorrowRate,
                currentHealthFactor,
                currentPrice,
                triggeredVectors
            ));
        }

        return (false, bytes(""));
    }
}
