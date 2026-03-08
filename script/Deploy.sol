// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingPoolCrisisResponse.sol";

contract MockLendingPool {

    uint256 private _reserveLiquidity    = 10000 ether;
    uint256 private _borrowRate          = 500;      // 5.00% in basis points
    uint256 private _avgHealthFactor     = 180;      // 1.80 scaled by 100
    uint256 private _oraclePrice         = 2000 ether; // $2000

    function getReserveLiquidity() external view returns (uint256) {
        return _reserveLiquidity;
    }

    function getBorrowRate() external view returns (uint256) {
        return _borrowRate;
    }

    function getAverageHealthFactor() external view returns (uint256) {
        return _avgHealthFactor;
    }

    function getOraclePrice() external view returns (uint256) {
        return _oraclePrice;
    }

    // Test helpers to simulate crisis conditions

    function simulateReserveDrain() external {
        _reserveLiquidity = 7000 ether; // 30% drain, triggers Vector 1
    }

    function simulateBorrowRateSpike() external {
        _borrowRate = 800; // 60% spike from 500, triggers Vector 2
    }

    function simulateHealthFactorCollapse() external {
        _avgHealthFactor = 150; // 17% drop from 180, triggers Vector 3
    }

    function simulatePriceDrift() external {
        _oraclePrice = 1700 ether; // 15% drop from 2000, triggers Vector 4
    }

    function simulateFullCrisis() external {
        _reserveLiquidity = 7000 ether;
        _borrowRate       = 800;
        _avgHealthFactor  = 150;
        _oraclePrice      = 1700 ether;
    }

    function resetState() external {
        _reserveLiquidity = 10000 ether;
        _borrowRate       = 500;
        _avgHealthFactor  = 180;
        _oraclePrice      = 2000 ether;
    }
}

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        MockLendingPool mock = new MockLendingPool();
        LendingPoolCrisisResponse response = new LendingPoolCrisisResponse();

        console.log("MockLendingPool deployed at:", address(mock));
        console.log("Response deployed at:", address(response));

        vm.stopBroadcast();
    }
}
