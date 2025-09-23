# ETF Strategy Hooks

A PancakeSwap Infinity (Uniswap V4 fork) hook implementation for ETF (Exchange-Traded Fund) strategy with automatic tax collection and fee distribution.

## Features

- **Tax Strategy Hook**: Automatically collects fees on swaps and distributes them between strategy treasury and development
- **Configurable Fee Structure**: 10% developer fees, 90% strategy fees (configurable via constants)
- **Multi-Currency Support**: Handles both native ETH and ERC20 token fees with automatic conversion
- **Safe Fee Distribution**: Secure ETH transfers and treasury integration
- **Comprehensive Testing**: Full test suite with mock contracts for treasury simulation

## Architecture

### Core Contracts

- **`CLTaxStrategyHook`**: Main hook contract implementing the tax strategy
- **`CLBaseHook`**: Base hook functionality and common utilities
- **`CLFullRangeHook`**: Full range liquidity hook implementation

### Key Features

- **After Swap Hook**: Executes fee collection after each swap transaction
- **Automatic Conversion**: Converts fee tokens to ETH when necessary
- **Treasury Integration**: Distributes strategy fees to treasury contract via `ITreasury` interface
- **Developer Fees**: Direct ETH transfer to configurable fee recipient address
- **Price Limit Safety**: Implements price limit checks for swap operations

## Prerequisites

1. Install Foundry: https://book.getfoundry.sh/getting-started/installation
2. Clone the repository
3. Install dependencies

## Installation & Setup

1. **Install dependencies**
   ```bash
   forge install
   ```

2. **Build the project**
   ```bash
   forge build
   ```

3. **Run tests**
   ```bash
   forge test
   ```

4. **Run tests with verbosity**
   ```bash
   forge test -vvv
   ```

## Testing

The project includes comprehensive tests covering:

- Fee collection mechanisms
- Treasury integration
- ETH and ERC20 token handling
- Edge cases and error conditions
- Gas optimization scenarios

Run specific test files:
```bash
forge test --match-contract CLTaxStrategyHookTest
```

## Configuration

### Fee Structure
- **Hook Fee Percentage**: 10% (100,000 / 1,000,000)
- **Strategy Fee Percentage**: 90% (900,000 / 1,000,000)
- **Fee Denominator**: 1,000,000 (for precise percentage calculations)

### Deployment Parameters
- `poolManager`: PancakeSwap CL Pool Manager address
- `feeAddress`: Address to receive developer fees

## Usage Example

```solidity
// Deploy the hook
CLTaxStrategyHook hook = new CLTaxStrategyHook(
    poolManager,     // ICLPoolManager instance
    feeRecipient     // Developer fee recipient address
);

// The hook automatically:
// 1. Collects 10% fee on each swap
// 2. Converts non-ETH fees to ETH
// 3. Distributes 90% to strategy treasury
// 4. Sends 10% to developer address
```

## Hook Permissions

The `CLTaxStrategyHook` registers with the following permissions:
- `afterSwap`: ✅ (fee collection)
- `afterSwapReturnDelta`: ✅ (delta modification)
- All other hooks: ❌

## Security Considerations

- Fee recipient address validation (non-zero address)
- Safe ETH transfers with revert on failure
- Proper handling of swap deltas and currency settlements
- Protected fee address updates (only current fee recipient)

## License

MIT License - see LICENSE file for details.
