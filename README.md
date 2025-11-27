# Solidity-learnings-foundry-lottery 🧪🎟️

This repository is a Foundry-based hands-on project that implements a Raffle (lottery) smart contract powered by Chainlink VRF (v2 / v2.5 style + VRFConsumerBaseV2Plus). It demonstrates how to write a provably-fair raffle that uses Chainlink to pick a winner at random, along with unit tests and Foundry scripts for local development and deployments.

Highlights:
- Raffle contract using Chainlink VRF for randomness
- Local mocks (VRFCoordinatorV2_5Mock + LinkToken mock) for unit testing with Foundry
- Foundry scripts for deploying and interacting with the contract locally or on Sepolia

---

## Table of contents

- Project overview
- Main components and files
- Tests (unit) — what is covered
- Local development and recommended commands
- Scripts and how they work
- Notes, tips and next steps

---

## Project overview

This project implements `Raffle.sol` which:

- Lets users enter the raffle by paying an entrance fee
- Periodically (interval) allows an external keeper to call `performUpKeep()` which triggers a Chainlink VRF request
- Uses `fulfillRandomWords` callback from VRF to pick a winner, reset the state, and transfer the collected funds to the winner

The implementation uses `VRFConsumerBaseV2Plus` and `VRFV2PlusClient.RandomWordsRequest` so it is compatible with the Chainlink VRF Coordinator (including a mock used for testing).

---

## Main files / directories

- `src/Raffle.sol` — Main raffle contract (open → accepting players → request randomness → pick winner)
- `test/unit/RaffleTest.t.sol` — Unit tests covering the core raffle logic, upkeep checks, events, and integration with VRF mock
- `test/mocks/LinkToken.sol` — Simple ERC20-based LINK token mock used in local testing
- `script/DeployRaffle.s.sol` — Foundry script to deploy `Raffle` using configuration from `HelperConfig.s.sol`
- `script/HelperConfig.s.sol` — Centralized per-network settings and local mock setup (supports Sepolia and local anvil/Anvil/Foundry flows)
- `script/Interactions.s.sol` — Helper scripts for creating/funding subscriptions and adding consumers (used during local flows and remote deployments)
- `lib/` — Third-party libs (Chainlink, forge-std, etc.)

---

## Tests — what we implemented

The unit tests in `test/unit/RaffleTest.t.sol` are implemented using Foundry (Forge) and cover the following scenarios:

- Initialization: contract starts in `OPEN` state
- enterRaffle() behavior:
	- Reverts when msg.value < entrance fee
	- Records players correctly
	- Emits `RaffleEnter` event
	- Prevents entering while raffle is `CALCULATING`
- checkUpkeep() logic:
	- Returns false if contract has no balance
	- Returns false if raffle is not open
	- Returns false if not enough time has passed
	- Returns true when all conditions (open, time passed, players, contract has balance) are met
- performUpKeep() logic:
	- Only runs if `checkUpkeep()` is true
	- Reverts with `UpkeepNotNeeded` if conditions aren't met
	- Updates state and emits a request ID (randomness request)
- fulfillRandomWords() flow (using `VRFCoordinatorV2_5Mock`):
	- Ensures fulfillment can only be called after `performUpKeep`
	- On valid fulfillment, picks a winner, resets players and state, transfers the prize

The tests use typical Foundry helpers:

- `vm.prank`, `hoax`, `vm.warp`, `vm.roll` to manipulate accounts and chain/time
- `vm.expectRevert`, `vm.expectEmit`, `vm.recordLogs` to assert on events, revert reasons and emitted logs
- Local mocks: `VRFCoordinatorV2_5Mock` (Chainlink mock) and `test/mocks/LinkToken.sol`

---

## How the local / test setup works

- `HelperConfig.s.sol` prepares two common configurations: Sepolia and local Anvil/Foundry environment. For local mode it deploys the `VRFCoordinatorV2_5Mock` and `LinkToken` mock so tests and scripts can interact with a simulated Chainlink setup.
- The script `DeployRaffle.s.sol` uses `HelperConfig` to decide whether to use a remote config (Sepolia) or a local ephemeral config (Anvil). It also runs helper scripts for creating/funding subscriptions and adding consumers.

---

## Common development commands (Foundry)

These commands are standard for Foundry-based projects.

Install Foundry (if not installed):

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Build sources:

```bash
forge build
```

Run unit tests (with verbose output):

```bash
forge test -vv
```

Format code:

```bash
forge fmt
```

Run anvil (local node) for integration debugging:

```bash
anvil
```

Run scripts (example):

```bash
# Deploy on local dev chain using DeployRaffle script
forge script script/DeployRaffle.s.sol:DeployRaffle --fork-url http://127.0.0.1:8545 -s

# Use Interactions scripts to fund subscription / add consumer
forge script script/Interactions.s.sol:FundSubscription --fork-url http://127.0.0.1:8545 -s
```

Note: the project uses Chainlink mocks locally. For real deployment on Sepolia or Mainnet you must configure `HelperConfig.s.sol` with appropriate values and a funded Chainlink subscription.

---

## Useful pointers and next steps 💡

- This repo is a learning implementation — you can extend it by adding:
	- front-end UI to interact with the raffle contract
	- additional tests to stress edge cases (re-entrancy, gas issues, fallback behaviors)
	- fuzz and property-based tests to increase coverage
	- TypeScript / Hardhat scripts if you prefer a JS dev flow
- Security note: Always audit contracts before real mainnet deployments and follow Chainlink guidelines for subscription funding, keeping callbackGasLimit in check, and verifying gas lane keys.

---

If you'd like, I can also:

- Add a small Getting Started section for beginners with step-by-step commands for running tests locally
- Create a short CONTRIBUTING.md or TEMPLATE to show how to add a new test or change configuration

Enjoy exploring the raffle contract and Foundry workflows! ✅
