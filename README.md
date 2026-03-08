# 🛡️ Lending Pool Crisis Detector

> A production-grade Drosera Network trap deployed on Hoodi Testnet that detects DeFi lending pool crises through **temporal delta analysis** across a 5-block window — catching liquidity crises, borrow rate spikes, health factor collapses, and oracle manipulation as they develop in real time.

---

## 🔍 Overview

DeFi lending pools are among the most targeted protocols in the ecosystem. A coordinated attack — draining reserves, spiking borrow rates, collapsing health factors, and manipulating oracles simultaneously — can render a pool insolvent within minutes.

This trap uses **Drosera's historical sample model** (`block_sample_size = 5`) to compare current block data against a 5-block historical window. It detects **change over time**, not just absolute thresholds — making it a genuine crisis detector, not a simple alarm.

The trap fires only when **two or more vectors trigger simultaneously**, eliminating false positives while ensuring no coordinated attack goes undetected.

---

## ⚡ Attack Vectors Monitored

| Vector | Method | Condition | Threshold |
|--------|--------|-----------|-----------|
| 1 — Reserve Drain | **Delta** (data[0] vs data[4]) | Liquidity dropped vs 5 blocks ago | > 20% drop across window |
| 2 — Borrow Rate Spike | **Delta** (data[0] vs data[4]) | Borrow rate jumped vs 5 blocks ago | > 40% spike across window |
| 3 — Health Factor Collapse | **Delta** (data[0] vs data[4]) | Avg health factor dropped vs 5 blocks ago | > 15% drop across window |
| 4 — Price Feed Drift | **Delta** (data[0] vs data[4]) | Oracle price moved vs 5 blocks ago | > 10% in either direction |

**Why deltas matter:**
- A borrow rate of 8% means nothing alone — but 5% → 8% across 5 blocks is a utilization crisis signal
- A health factor of 1.50 means nothing alone — but 1.80 → 1.50 across 5 blocks is a liquidation cascade signal
- Deltas catch coordinated attacks as they develop, not after they complete

**Response logic:** Fires if **≥ 2 vectors** trigger simultaneously.

---

## 🏗️ Architecture

```
lending-pool-crisis-detector/
├── src/
│   ├── LendingPoolCrisisTrap.sol       # Temporal delta monitor
│   └── LendingPoolCrisisResponse.sol   # Authorized response emitter
├── script/
│   └── Deploy.sol                      # Deploys MockLendingPool + Response
├── drosera.toml                        # Drosera trap configuration
└── README.md
```

### How It Works

1. **Every block**, Drosera calls `collect()` — reads 4 storage slots from MockLendingPool
2. Drosera accumulates 5 blocks of snapshots: `data[0]` (current) → `data[4]` (oldest)
3. `shouldRespond()` computes **deltas** between `data[0]` and `data[data.length - 1]`
4. Vector 1: Did liquidity drop > 20% since 5 blocks ago?
5. Vector 2: Did borrow rate spike > 40% since 5 blocks ago?
6. Vector 3: Did average health factor drop > 15% since 5 blocks ago?
7. Vector 4: Did oracle price move > 10% in either direction since 5 blocks ago?
8. If ≥ 2 vectors breach → response fires with full context

---

## 📋 Contract Addresses (Hoodi Testnet)

| Contract | Address |
|----------|---------|
| 🪤 Trap | [`0x755F3f648914099934eb51061d10C3307396815D`](https://hoodi.etherscan.io/address/0x755F3f648914099934eb51061d10C3307396815D) |
| ⚡ Response | [`0x67f8Be1f754d2D7b554B31502AB5c33dE0Db69eA`](https://hoodi.etherscan.io/address/0x67f8Be1f754d2D7b554B31502AB5c33dE0Db69eA) |
| 🎭 MockLendingPool | [`0x39C2C61b561F5384E74883acB442E43aCF81bb8d`](https://hoodi.etherscan.io/address/0x39C2C61b561F5384E74883acB442E43aCF81bb8d) |

---

## 🔧 Drosera Configuration

| Parameter | Value | Reason |
|-----------|-------|--------|
| Network | Hoodi Testnet | — |
| Chain ID | 560048 | — |
| Block Sample Size | **5** | Enables 5-block delta analysis |
| Cooldown Period | 33 blocks | Prevents response spam |
| Min Operators | 1 | — |
| Max Operators | 3 | — |
| Private Trap | false | Open to all Hoodi operators |

---

## 🧪 Testing the Trap

The `MockLendingPool` contract exposes helper functions to simulate crisis conditions:

```bash
# Simulate reserve drain (triggers Vector 1)
cast send 0x39C2C61b561F5384E74883acB442E43aCF81bb8d "simulateReserveDrain()" \
  --rpc-url https://eth-hoodi.g.alchemy.com/v2/7Noy1ZKpVSfB7EZYc0tei --private-key $PRIVATE_KEY

# Simulate borrow rate spike (triggers Vector 2)
cast send 0x39C2C61b561F5384E74883acB442E43aCF81bb8d "simulateBorrowRateSpike()" \
  --rpc-url https://eth-hoodi.g.alchemy.com/v2/7Noy1ZKpVSfB7EZYc0tei --private-key $PRIVATE_KEY

# Simulate health factor collapse (triggers Vector 3)
cast send 0x39C2C61b561F5384E74883acB442E43aCF81bb8d "simulateHealthFactorCollapse()" \
  --rpc-url https://eth-hoodi.g.alchemy.com/v2/7Noy1ZKpVSfB7EZYc0tei --private-key $PRIVATE_KEY

# Simulate price feed drift (triggers Vector 4)
cast send 0x39C2C61b561F5384E74883acB442E43aCF81bb8d "simulatePriceDrift()" \
  --rpc-url https://eth-hoodi.g.alchemy.com/v2/7Noy1ZKpVSfB7EZYc0tei --private-key $PRIVATE_KEY

# Simulate full crisis (triggers all 4 vectors)
cast send 0x39C2C61b561F5384E74883acB442E43aCF81bb8d "simulateFullCrisis()" \
  --rpc-url https://eth-hoodi.g.alchemy.com/v2/7Noy1ZKpVSfB7EZYc0tei --private-key $PRIVATE_KEY

# Reset all conditions to healthy state
cast send 0x39C2C61b561F5384E74883acB442E43aCF81bb8d "resetState()" \
  --rpc-url https://eth-hoodi.g.alchemy.com/v2/7Noy1ZKpVSfB7EZYc0tei --private-key $PRIVATE_KEY
```

To trigger the response, run **any two** simulate commands then wait 5 blocks for the delta to register.

---

## 🔐 Security Design

- **Stateless Trap:** No storage variables — safe against Drosera's shadow-fork redeployment model
- **Temporal Delta Analysis:** Compares `data[0]` vs `data[4]` — detects change over time, not just state
- **Data Length Guard:** `shouldRespond()` validates input before decoding — prevents revert on empty blobs
- **onlyOperator Authorization:** Response contract uses operator-based access control — aligned with Drosera's executor model
- **Math Safety:** All division and subtraction operations are guarded against zero and underflow
- **Bidirectional Price Check:** Oracle drift detected in both directions — catches both crashes and pump manipulation

---

## 🛠️ Local Development

```bash
# Clone the repository
git clone https://github.com/JustSam-20/lending-pool-crisis-detector.git
cd lending-pool-crisis-detector

# Install dependencies
forge install

# Compile
forge build

# Run Drosera dryrun
drosera dryrun
```

---

## 📡 Built With

- [Drosera Network](https://drosera.io) — Blockchain monitoring infrastructure
- [Foundry](https://book.getfoundry.sh) — Smart contract development toolchain
- [Hoodi Testnet](https://hoodi.ethpandaops.io) — Ethereum testnet

---

*Built as part of the Drosera Network operator program.*
