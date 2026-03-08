// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LendingPoolCrisisResponse {

    mapping(address => bool) public authorizedOperators;
    address public owner;

    event LendingPoolCrisisDetected(
        uint256 currentLiquidity,
        uint256 currentBorrowRate,
        uint256 currentHealthFactor,
        uint256 currentPrice,
        uint8 triggeredVectors,
        uint256 timestamp
    );

    event OperatorAuthorized(address operator);
    event OperatorRevoked(address operator);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyOperator() {
        require(authorizedOperators[msg.sender], "not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedOperators[msg.sender] = true;
    }

    function authorizeOperator(address operator) external onlyOwner {
        authorizedOperators[operator] = true;
        emit OperatorAuthorized(operator);
    }

    function revokeOperator(address operator) external onlyOwner {
        authorizedOperators[operator] = false;
        emit OperatorRevoked(operator);
    }

    function respond(
        uint256 currentLiquidity,
        uint256 currentBorrowRate,
        uint256 currentHealthFactor,
        uint256 currentPrice,
        uint8 triggeredVectors
    ) external onlyOperator {
        emit LendingPoolCrisisDetected(
            currentLiquidity,
            currentBorrowRate,
            currentHealthFactor,
            currentPrice,
            triggeredVectors,
            block.timestamp
        );
    }
}
