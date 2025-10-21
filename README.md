# TransactionFrequencyTrap (Drosera Proof-of-Concept)

## Overview

This trap is designed to monitor and respond to unusual spikes in transaction frequency targeting a specific address on the Hoodi Testnet. It is critical for defending against spamming, denial-of-service attempts, or specific economic exploits that rely on rapid transaction submissions.

## What It Does

  * Monitors the total number of transactions sent to a designated address within a rolling block window.
  * **Triggers** if the transaction count exceeds a defined threshold within that short window, indicating a spike in activity.
  * It demonstrates the essential Drosera trap pattern using deterministic off-chain logic.

## Key Files

  * `src/TransactionFrequencyTrap.sol` – The core trap contract containing the monitoring logic.
  * `src/SimpleResponder.sol` – The required external response contract that executes the action.
  * `drosera.toml` – The deployment, configuration, and operator-specific settings file.
  * `foundry.toml` – The Foundry configuration file, crucial for handling dependencies and remappings.

## Detection Logic

The trap's core monitoring logic is contained in the deterministic `shouldRespond()` function, which compares the current transaction count to a previously sampled count.

```solidity
// The logic compares the current total count to a count from a previous block.
function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
    CollectOutput memory current = abi.decode(data[0], (CollectOutput));
    CollectOutput memory past = abi.decode(data[data.length - 1], (CollectOutput));

    // Checks if the count increase over the sampled period exceeds the THRESHOLD.
    if (current.transactionCount > past.transactionCount + THRESHOLD) { 
        return (true, bytes("Transaction frequency spike detected."));
    }
    return (false, bytes(""));
}
```

##  Implementation Details and Key Concepts

  * **Monitoring Target:** Watching the cumulative transaction count targeting a specified address (`TARGET_ADDRESS`).
  * **Threshold:** The `THRESHOLD` constant (`10` in your code) defines the maximum allowable increase in transactions over the `block_sample_size` period.
  * **Deterministic Logic:** The `shouldRespond()` function is executed off-chain by a decentralized network of operators to achieve consensus before a single transaction is proposed.
  * **Response Mechanism:** On trigger, the trap calls the external `SimpleResponder` contract, demonstrating the separation of monitoring and corrective action.

## Test It

To verify the trap logic using Foundry, run the following command (assuming a test file has been created, e.g., `test/TransactionFrequencyTrap.t.sol`):

```bash
forge test --match-contract TransactionFrequencyTrap
```

