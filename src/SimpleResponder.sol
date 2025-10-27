// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleResponder {
    // Renamed from 'trap' to 'droseraRelay' as this is the actual caller.
    address public immutable droseraRelay;

    // Optional: store last spike delta
    uint256 public lastDelta;

    event SpikeDetected(uint256 delta, uint256 atBlock);
    event UnauthorizedCall(address caller, uint256 when);

    // Constructor now takes the address of the Drosera Relay from drosera.toml
    constructor(address _droseraRelay) {
        require(_droseraRelay != address(0), "Relay must not be zero");
        droseraRelay = _droseraRelay;
    }

    // Modifier checks if the caller is the Drosera Relay.
    modifier onlyRelay() {
        if (msg.sender != droseraRelay) {
            // emit something for debugging, but do not revert
            emit UnauthorizedCall(msg.sender, block.number);
            return; 
        }
        _;
    }

    // Function restricted to the Drosera Relay address.
    function respondCallback(uint256 amount) external onlyRelay {
        // Keep the spike delta
        lastDelta = amount;

        // Emit logs for dashboards / explorers
        emit SpikeDetected(amount, block.number);

      
    }
}
