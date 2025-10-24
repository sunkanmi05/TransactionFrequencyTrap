// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleResponder {
 
    // Only the trap that you wire into drosera.toml can call respondCallback
    address public immutable trap;

    // Optional: store last spike delta
    uint256 public lastDelta;

  
    event SpikeDetected(uint256 delta, uint256 atBlock);
    event UnauthorizedCall(address caller, uint256 when);

  
    constructor(address _trap) {
        require(_trap != address(0), "Trap must not be zero");
        trap = _trap;
    }

    
    modifier onlyTrap() {
        if (msg.sender != trap) {
            // emit something for debugging, but do not revert
            emit UnauthorizedCall(msg.sender, block.number);
            return;
        }
        _;
    }

   
    function respondCallback(uint256 amount) external onlyTrap {
        // Keep the spike delta
        lastDelta = amount;

        // Emit logs for dashboards / explorers
        emit SpikeDetected(amount, block.number);

        // --- OPTIONAL REAL LOGIC ---
        // You could:
        // - ping a contract
        // - rebalance liquidity
        // - pause a vault
        // - update a state machine
        // - trigger an oracle update
        // etc.
    }
}
