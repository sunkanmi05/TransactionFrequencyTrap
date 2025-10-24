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

The trap uses Drosera’s deterministic planning model to detect spikes in ERC-20 Transfer activity emitted by a target contract. Instead of relying on synthetic counters, it collects real on-chain logs (EventLog[]) and compares the most recent window of events against the previous one.

```solidity
During each planning epoch:

collect():

Fetches filtered Transfer logs from the target contract

Encodes (EventLog[], blockNumber)

shouldRespond():

Safely guards against empty data during planning

Decodes the two most recent samples

Counts how many Transfer events occurred within a rolling window (default: 30 blocks)

Computes the delta (spike amount)

Returns (true, abi.encode(delta)) if that spike exceeds a configurable threshold

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

    uint256 minCurr = currBlk > WINDOW ? currBlk - WINDOW + 1 : 0;
    uint256 minPrev = prevBlk > WINDOW ? prevBlk - WINDOW + 1 : 0;

    uint256 currCount;
    for (uint256 i; i < currLogs.length; i++) {
        if (currLogs[i].blockNumber >= minCurr) currCount++;
    }

    uint256 prevCount;
    for (uint256 i; i < prevLogs.length; i++) {
        if (prevLogs[i].blockNumber >= minPrev) prevCount++;
    }

    uint256 delta = currCount > prevCount ? currCount - prevCount : 0;

    if (delta > THRESHOLD) {
        return (true, abi.encode(delta));
    }

    return (false, abi.encode(uint256(0)));
}

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

