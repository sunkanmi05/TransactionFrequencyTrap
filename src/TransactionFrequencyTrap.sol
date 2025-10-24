// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    Trap,
    EventFilter,
    EventLog,
    EventFilterLib
} from "drosera-contracts/Trap.sol";

contract TransactionFrequencyTrap is Trap {
    using EventFilterLib for EventFilter;

    // ERC-20 to monitor
    address public constant TARGET =
        0xFba1bc0E3d54D71Ba55da7C03c7f63D4641921B1;

    // keccak256("Transfer(address,address,uint256)")
    bytes32 public constant TRANSFER_SIG =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    uint256 public constant THRESHOLD = 10; // spike amount
    uint256 public constant WINDOW = 30;    // block window

    constructor() {}

    // Called by Drosera operators to collect logs
    function collect() external view override returns (bytes memory) {
        EventFilter memory filter = EventFilter({
            address_: TARGET,
            topics: new bytes32
        });

        // Filter Transfer events
        filter.topics[0] = TRANSFER_SIG;

        EventLog[] memory logs = filter.collectLogs();

        return abi.encode(logs, block.number);
    }

    // Detect spikes
    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        if (data.length < 2 || data[0].length == 0 || data[1].length == 0) {
            return (false, abi.encode(uint256(0)));
        }

        (EventLog[] memory currLogs, uint256 currBlk) =
            abi.decode(data[0], (EventLog[], uint256));

        (EventLog[] memory prevLogs, uint256 prevBlk) =
            abi.decode(data[1], (EventLog[], uint256));

        // window begin markers
        uint256 minCurr = currBlk > WINDOW ? currBlk - WINDOW + 1 : 0;
        uint256 minPrev = prevBlk > WINDOW ? prevBlk - WINDOW + 1 : 0;

        // count recent logs
        uint256 currCount;
        for (uint256 i; i < currLogs.length; i++) {
            if (currLogs[i].blockNumber >= minCurr) currCount++;
        }

        uint256 prevCount;
        for (uint256 i; i < prevLogs.length; i++) {
            if (prevLogs[i].blockNumber >= minPrev) prevCount++;
        }

        // compute delta
        uint256 delta = currCount > prevCount ? currCount - prevCount : 0;

        if (delta > THRESHOLD) {
            return (true, abi.encode(delta));
        }

        return (false, abi.encode(uint256(0)));
    }
}
