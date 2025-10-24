// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/interfaces/ITrap.sol";

contract TransactionFrequencyTrap is ITrap {
    uint256 public constant THRESHOLD = 10;

    struct CollectOutput {
        uint256 blockNumber;
        uint256 transactionCount;
    }

    constructor() {}

    function collect() external view override returns (bytes memory) {
        uint256 pseudoCount = block.number % 100;
        return abi.encode(
            CollectOutput({
                blockNumber: block.number,
                transactionCount: pseudoCount
            })
        );
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");
        if (data[0].length == 0 || data[data.length - 1].length == 0) return (false, "");

        CollectOutput memory latest = abi.decode(data[data.length - 1], (CollectOutput));
        CollectOutput memory previous = abi.decode(data[data.length - 2], (CollectOutput));

        uint256 delta = latest.transactionCount - previous.transactionCount;

        if (delta > THRESHOLD) {
            return (true, abi.encode(delta));
        }

        return (false, "");
    }
}
