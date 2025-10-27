// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    Trap,
    EventFilter
    // Removed unused imports: EventLog, EventFilterLib
} from "drosera-contracts/Trap.sol";

// Note: No need for 'using EventFilterLib for EventFilter;' here

contract TransactionFrequencyTrap is Trap {
    // ERC-20 to monitor (This address should be correct for your token)
    address public constant TARGET =
        0xFba1bc0E3d54D71Ba55da7C03c7f63D4641921B1;

    // keccak256("Transfer(address,address,uint256)")
    // Note: This constant is not needed if using the string signature in eventLogFilters
    // bytes32 public constant TRANSFER_SIG = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    uint256 public constant THRESHOLD = 10; // spike amount
    uint256 public constant WINDOW = 30;    // block window

    constructor() {}

    // 1. **FIXED API MISUSE:** Define filters for Drosera to collect logs
    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](1);
        
        // Define the filter using the correct struct fields and event signature
        filters[0] = EventFilter({
            contractAddress: TARGET,
            signature: "Transfer(address,address,uint256)" // Using string signature
        });
        return filters;
    }

    // 2. **FIXED API MISUSE:** Use the built-in getEventLogs() provided by the Trap base
    function collect() external view override returns (bytes memory) {
        // This function now uses the filters defined in eventLogFilters()
        EventLog[] memory logs = getEventLogs(); 
        
        // Return logs and current block number, as expected by shouldRespond()
        return abi.encode(logs, block.number);
    }

    // Detect spikes
    // NOTE: This logic remains the same, but relies on the correctly formatted payload from collect()
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
