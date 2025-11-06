// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    Trap,
    EventFilter,
    EventLog // FIX: Missing import
} from "drosera-contracts/Trap.sol";

// Note: This trap detects a spike in the number of ERC-20 Transfer events
// emitted by the TARGET token, which serves as a proxy for "transaction frequency"
contract TransactionFrequencyTrap is Trap {
    // ERC-20 to monitor
    address public constant TARGET =
        0xFba1bc0E3d54D71Ba55da7C03c7f63D4641921B1;

    uint256 public constant THRESHOLD = 10; // Spike amount (delta of logs)
    // uint256 public constant WINDOW = 30; // WINDOW is not needed in the simplified logic

    constructor() {}

    // 1. Define filters for Drosera to collect logs from the TARGET contract
    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](1);
        
        // Filter for all Transfer events emitted by the TARGET token
        filters[0] = EventFilter({
            contractAddress: TARGET,
            signature: "Transfer(address,address,uint256)" 
        });
        return filters;
    }

    // 2. FIX: Simplified collect() to count logs, avoiding blockNumber per-log checks.
    // This is the safest approach given the uncertainty of EventLog fields.
    function collect() external view override returns (bytes memory) {
        // Use the built-in getEventLogs() provided by the Trap base
        EventLog[] memory logs = getEventLogs(); 
        
        // Return the count of logs and the current block number
        uint256 count = logs.length;
        return abi.encode(count, block.number);
    }

    /**
     * @notice Compares the number of logs (count) between the newest (data[0]) and previous (data[1]) collection.
     * @param data Array of historical data points (count, block.number).
     * @return (bool, bytes) A boolean indicating if a response is needed, and the payload (delta).
     */
    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        // FIX: Planner safety check
        // Check for at least 2 samples and non-empty payloads
        if (data.length < 2 || data[0].length == 0 || data[1].length == 0) {
            // FIX: Ensure a payload is returned, even when false, to match responder ABI
            return (false, abi.encode(uint256(0))); 
        }

        // FIX: Decode only count and block.number (which is only used to label the sample)
        (uint256 currCount, ) = abi.decode(data[0], (uint256, uint256));
        (uint256 prevCount, ) = abi.decode(data[1], (uint256, uint256));
        
        // FIX: Removed block window logic, as it's not applicable to simple count comparison

        // compute delta: current count vs. previous count
        uint256 delta = currCount > prevCount ? currCount - prevCount : 0;

        if (delta > THRESHOLD) {
            // FIX: Returns delta to match respondCallback(uint256)
            return (true, abi.encode(delta)); 
        }

        return (false, abi.encode(uint256(0)));
    }
}
