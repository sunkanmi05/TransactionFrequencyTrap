

##  Transaction Frequency Spike Trap (Drosera Proof-of-Concept)

### Overview

This trap is designed to monitor and respond to unusual spikes in the **rate of ERC-20 Transfer events** emitted by a specific token. It serves as a proxy for detecting a sudden flood of transactions involving that token, which can indicate unusual market activity, bot front-running, or other exploit attempts.

### What It Does

  * Monitors the **total number of `Transfer` events** emitted by a designated **`TARGET`** token during each sampling epoch.
  * Triggers if the **increase in event count (delta)** between the newest sample and the previous sample exceeds a defined **`THRESHOLD`**.
  * It demonstrates the essential Drosera trap pattern using deterministic off-chain logic for log analysis.

### Key Files

  * `src/TransactionFrequencyTrap.sol` – The core trap contract containing the monitoring logic.
  * `src/SimpleResponder.sol` – The required external response contract that executes the action.
  * `drosera.toml` – The deployment, configuration, and operator-specific settings file.

### Detection Logic

The trap uses Drosera's deterministic planning model to detect spikes in ERC-20 `Transfer` activity. It collects the logs (`EventLog[]`) and then reduces the data to a simple count, comparing the event frequency between two distinct samples.

During each planning epoch, the logic performs the following steps:

1.  **`collect()`**

      * Fetches filtered `Transfer` logs from the `TARGET` token using the `eventLogFilters` defined in the trap.
      * **Calculates the total number of logs (`logs.length`).**
      * Encodes the collected data as a tuple: `(uint256 logCount, uint256 currentBlockNumber)`.

2.  **`shouldRespond()`**

      * Safely guards against empty or incomplete data during the planning process.
      * **Decodes the two most recent samples as simple counts:** `(currCount, currBlk)` and `(prevCount, prevBlk)`.
      * Computes the **delta (spike amount)** between the `currCount` and the `prevCount`.
      * Returns `(true, abi.encode(delta))` if that spike (`delta`) exceeds the configurable **`THRESHOLD`** (default: 10).

### ⚙️ Solidity Implementation (Key Logic)

The complexity of checking each log's `blockNumber` is eliminated, ensuring robustness across different `EventLog` definitions.

```solidity
function shouldRespond(bytes[] calldata data)
    external
    pure
    override
    returns (bool, bytes memory)
{
    // Safety guards...
    // FIX: Decodes only the count (uint256) and block number
    (uint256 currCount, ) = abi.decode(data[0], (uint256, uint256));
    (uint256 prevCount, ) = abi.decode(data[1], (uint256, uint256));
    
    // FIX: Simple count comparison (no WINDOW logic needed)
    uint256 delta = currCount > prevCount ? currCount - prevCount : 0;

    if (delta > THRESHOLD) {
        return (true, abi.encode(delta)); // Returns the delta (uint256)
    }

    return (false, abi.encode(uint256(0)));
}
```

### Implementation Details and Key Concepts

  * **Monitoring Metric:** Watching the **increase in `Transfer` event count** between samples.
  * **Resilience:** The trap design is resilient because it only relies on the **number of logs** collected, not on the `blockNumber` field within the `EventLog` struct itself.
  * **Threshold:** The `THRESHOLD` constant (10 in the code) defines the maximum allowable increase in events over the `block_sample_size` period defined in `drosera.toml`.
  * **Response Mechanism:** On trigger, the trap returns the **`delta`** (the spike amount), which is consumed by the external `SimpleResponder` contract via the expected `respondCallback(uint256)` function.

### Test It

To verify the trap logic using Foundry, run the following command (assuming a test file has been created, e.g., `test/TransactionFrequencyTrap.t.sol`):

```bash
forge test --match-contract TransactionFrequencyTrap
```
