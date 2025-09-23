// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CLBaseHook} from "./CLBaseHook.sol";
import {ICLPoolManager} from "infinity-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {PoolKey} from "infinity-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "infinity-core/src/types/Currency.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "infinity-core/src/types/BalanceDelta.sol";
import {TickMath} from "infinity-core/src/pool-cl/libraries/TickMath.sol";
import {SafeCast} from "infinity-core/src/libraries/SafeCast.sol";
import {IVault} from "infinity-core/src/interfaces/IVault.sol";
import {IERC20Minimal} from "infinity-core/src/interfaces/IERC20Minimal.sol";

interface ITreasury {
    function addFees() external payable;
}

/// @title CLTaxStrategyHook
/// @notice A PancakeSwap CL hook that charges fees on swaps and distributes them between strategy and dev
/// @dev Implements tax strategy with automatic fee collection and distribution
contract CLTaxStrategyHook is CLBaseHook {
    using CurrencyLibrary for Currency;
    using SafeCast for uint256;
    using SafeCast for int128;

    /// @notice Fee percentage for hook operations (10%)
    uint256 public constant HOOK_FEE_PERCENTAGE = 100000;

    /// @notice Fee percentage for strategy operations (90%)
    uint256 public constant STRATEGY_FEE_PERCENTAGE = 900000;

    /// @notice Fee denominator for percentage calculations
    uint256 public constant FEE_DENOMINATOR = 1000000;

    /// @notice Maximum price limit for swaps
    uint160 private constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_RATIO - 1;

    /// @notice Minimum price limit for swaps
    uint160 private constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_RATIO + 1;

    /// @notice Address that receives developer fees
    address public feeAddress;

    /// @notice Emitted when fee address is updated
    event FeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice Emitted when fees are collected and processed
    event FeesProcessed(
        address indexed token,
        uint256 totalFee,
        uint256 strategyFee,
        uint256 devFee
    );

    /// @notice Constructor to initialize the hook
    /// @param _poolManager The PancakeSwap CL pool manager
    /// @param _feeAddress Address to receive developer fees
    constructor(
        ICLPoolManager _poolManager,
        address _feeAddress
    ) CLBaseHook(_poolManager) {
        require(
            _feeAddress != address(0),
            "CLTaxStrategyHook: fee address cannot be zero"
        );
        feeAddress = _feeAddress;
    }

    /// @notice Returns the hook permissions for this contract
    /// @return uint16 Bitmap representing enabled hooks
    function getHooksRegistrationBitmap()
        external
        pure
        override
        returns (uint16)
    {
        return
            _hooksRegistrationBitmapFrom(
                Permissions({
                    beforeInitialize: false,
                    afterInitialize: false,
                    beforeAddLiquidity: false,
                    afterAddLiquidity: false,
                    beforeRemoveLiquidity: false,
                    afterRemoveLiquidity: false,
                    beforeSwap: false,
                    afterSwap: true,
                    beforeDonate: false,
                    afterDonate: false,
                    beforeSwapReturnDelta: false,
                    afterSwapReturnDelta: true,
                    afterAddLiquidityReturnDelta: false,
                    afterRemoveLiquidityReturnDelta: false
                })
            );
    }

    /// @notice Hook called after each swap to collect fees
    /// @param key The pool key
    /// @param params Swap parameters
    /// @param delta Balance changes from the swap
    /// @return selector Function selector and fee amount taken
    function _afterSwap(
        address /* sender */,
        PoolKey calldata key,
        ICLPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata /* hookData */
    ) internal override returns (bytes4, int128) {
        // Determine which token was specified and calculate fee currency
        bool specifiedTokenIs0 = (params.amountSpecified < 0 ==
            params.zeroForOne);
        (Currency feeCurrency, int128 swapAmount) = (specifiedTokenIs0)
            ? (key.currency1, delta.amount1())
            : (key.currency0, delta.amount0());

        // Ensure we work with positive amounts
        if (swapAmount < 0) swapAmount = -swapAmount;

        // Calculate fee amount (1% of swap amount)
        uint256 feeAmount = (uint128(swapAmount) * HOOK_FEE_PERCENTAGE) /
            FEE_DENOMINATOR;

        // Skip if fee amount is zero
        if (feeAmount == 0) {
            return (this.afterSwap.selector, 0);
        }

        // Take fee from the pool
        _takeCurrency(feeCurrency, feeAmount);

        // Check if fee currency is native ETH
        bool isEthFee = Currency.unwrap(feeCurrency) == address(0);
        address token1Contract = Currency.unwrap(key.currency1);

        // Handle fee token conversion and processing
        if (!isEthFee) {
            // Convert fee token to ETH through swap
            uint256 feeInETH = _swapToEth(key, feeCurrency, feeAmount);
            _processFees(token1Contract, feeInETH);
        } else {
            // Fee is already in ETH
            _processFees(token1Contract, feeAmount);
        }

        return (this.afterSwap.selector, feeAmount.toInt128());
    }

    /// @notice Process collected fees by distributing between strategy and dev
    /// @param token1Contract Address of the token1 contract (treasury contract)
    /// @param feeAmount Total fee amount in ETH to distribute
    function _processFees(address token1Contract, uint256 feeAmount) internal {
        if (feeAmount == 0) return;

        // Calculate strategy and dev fees based on constants
        uint256 strategyFee = (feeAmount * STRATEGY_FEE_PERCENTAGE) /
            FEE_DENOMINATOR;
        uint256 devFee = feeAmount - strategyFee;

        // Deposit strategy fee to treasury contract
        if (strategyFee > 0) {
            ITreasury(token1Contract).addFees{value: strategyFee}();
        }

        // Send dev fee to fee recipient
        if (devFee > 0) {
            _safeTransferETH(feeAddress, devFee);
        }

        emit FeesProcessed(token1Contract, feeAmount, strategyFee, devFee);
    }

    /// @notice Swap fee tokens to ETH using the pool manager
    /// @param key The pool key for swapping
    /// @param feeCurrency The currency to swap from
    /// @param amount Amount of tokens to swap
    /// @return ETH amount received from the swap
    function _swapToEth(
        PoolKey memory key,
        Currency feeCurrency,
        uint256 amount
    ) internal returns (uint256) {
        uint256 ethBefore = address(this).balance;

        // Determine swap direction based on fee currency
        bool zeroForOne = Currency.unwrap(feeCurrency) ==
            Currency.unwrap(key.currency0);

        // Execute swap through pool manager
        BalanceDelta swapDelta = poolManager.swap(
            key,
            ICLPoolManager.SwapParams({
                zeroForOne: !zeroForOne, // Swap TO ETH (opposite direction)
                amountSpecified: -int256(amount), // Exact input
                sqrtPriceLimitX96: zeroForOne
                    ? MIN_PRICE_LIMIT
                    : MAX_PRICE_LIMIT
            }),
            bytes("")
        );

        // Handle settlement of swap results
        _settleSwapDelta(key, swapDelta);

        // Return the ETH received
        return address(this).balance - ethBefore;
    }

    /// @notice Settle the swap delta with the vault
    /// @param key The pool key
    /// @param delta Balance changes from the swap
    function _settleSwapDelta(PoolKey memory key, BalanceDelta delta) internal {
        // Handle currency0 settlement
        if (delta.amount0() < 0) {
            // We owe currency0 to the pool
            _settleCurrency(key.currency0, uint256(int256(-delta.amount0())));
        } else if (delta.amount0() > 0) {
            // We receive currency0 from the pool
            _takeCurrency(key.currency0, uint256(int256(delta.amount0())));
        }

        // Handle currency1 settlement
        if (delta.amount1() < 0) {
            // We owe currency1 to the pool
            _settleCurrency(key.currency1, uint256(int256(-delta.amount1())));
        } else if (delta.amount1() > 0) {
            // We receive currency1 from the pool
            _takeCurrency(key.currency1, uint256(int256(delta.amount1())));
        }
    }

    /// @notice Helper function to settle currency to vault
    /// @param currency Currency to settle
    /// @param amount Amount to settle
    function _settleCurrency(Currency currency, uint256 amount) internal {
        if (currency.isNative()) {
            vault.settle{value: amount}();
        } else {
            vault.sync(currency);
            IERC20Minimal(Currency.unwrap(currency)).transfer(
                address(vault),
                amount
            );
            vault.settle();
        }
    }

    /// @notice Helper function to take currency from vault
    /// @param currency Currency to take
    /// @param amount Amount to take
    function _takeCurrency(Currency currency, uint256 amount) internal {
        vault.take(currency, address(this), amount);
    }

    /// @notice Safe transfer of ETH
    /// @param to Address to send ETH to
    /// @param amount Amount of ETH to send
    function _safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "CLTaxStrategyHook: ETH transfer failed");
    }

    /// @notice Update the fee recipient address
    /// @param newFeeAddress New address to receive developer fees
    function updateFeeAddress(address newFeeAddress) external {
        require(
            msg.sender == feeAddress,
            "CLTaxStrategyHook: only fee address can update"
        );
        require(
            newFeeAddress != address(0),
            "CLTaxStrategyHook: new fee address cannot be zero"
        );

        address oldFeeAddress = feeAddress;
        feeAddress = newFeeAddress;

        emit FeeAddressUpdated(oldFeeAddress, newFeeAddress);
    }

    /// @notice Receive function to accept ETH fees and payments
    receive() external payable {}
}
