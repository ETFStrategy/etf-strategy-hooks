# ETFStrategy — Project Introduction & Quick Overview

**Website**: [https://etfstrategy.fun](https://etfstrategy.fun)  
**Twitter**: [etfstrategy_fun](https://x.com/etfstrategy_fun)  
**Github — Treasury**: https://github.com/ETFStrategy/etfstrategy-contracts  
**Github — Hook**: https://github.com/ETFStrategy/etf-strategy-hooks  

---
# ETFStrategy
_“Turn any token into a perpetual machine”_

---

## Vision & Mission

ETFStrategy is a DeFi ecosystem aiming to transform any token (especially promising altcoins) into a **sustainable revenue generator**, by means of automatic fee collection, intelligent treasury management, and buyback & burn strategies.

Long-term vision: to build a smart treasury that uses collected fees to invest in potential ETF-candidate tokens (e.g. SOL, XRP, AVAX), generate profit, and use some of that profit to buy back & burn the native token (if applicable), thereby increasing deflationary pressure within the ecosystem.

---

## Core Mechanics & Workflow

The project centers around two main smart contracts:

- **Hook contract** (deployed as a PancakeSwap V4 / Infinity hook) — deployed at:  
  `0x69c1aC6eaFc46eb8F92b6c3Ec44c24Dc610A586d` on BSC.

- **Treasury contract** — handles the assets collected, implements investment strategies, profit withdrawal, buyback & burn.

Here is the flow:

1. **Automatic fee collection (10%) on every swap**  
   - The Hook is attached to the swap pool and implements `afterSwap`.  
   - On each swap, the hook automatically “takes” 10% of the output token as a fee.  
   - If the collected token is not BNB, the hook swaps it internally into BNB.

2. **Fee distribution (in BNB)**  
   - 90% of the fee (in BNB) is forwarded into the Treasury via the `addFees()` function to be used for investing.  
   - 10% is sent to the development / dev fund address (`feeAddress`).

3. **Treasury management & profit strategy**  
   - When assets in the treasury grow sufficiently (by preset rules), the system triggers profit-taking if a ~10% gain target is met.  
   - The profits are used, in part, to buy back the native token (if one exists) and burn it.  
   - This helps impose deflationary pressure while the underlying investments grow.

4. **Security & integration with PancakeSwap Hooks architecture**  
   - The Hook only intervenes in `afterSwap`, and it requires returning a delta so that accounting stays balanced.  
   - The Hook calls vault / pool manager functions (following the Hook standard for PancakeSwap Infinity).  
   - The Treasury is a terminal contract that receives BNB and executes investment logic.

---

## Tokenomics / Fee & Cash Flow

| Component            | Rate / Mechanism                            | Notes                                                  |
|----------------------|---------------------------------------------|---------------------------------------------------------|
| Swap fee             | **10%** on the output token for every transaction | Automatically collected by Hook                         |
| Conversion to BNB     | If collected token ≠ BNB → internal swap     | Ensures fees are unified in BNB                          |
| Fee distribution      | **90%** → Treasury ; **10%** → Dev / `feeAddress` | Dev fund supports ongoing development                    |
| Investment & profit  | BNB in Treasury is deployed into alt tokens  | Strategy of “buy, hold, take profit, burn”               |
| Buyback & Burn        | Use profits to buy native tokens → burn     | Adds deflationary pressure & supports price             |
