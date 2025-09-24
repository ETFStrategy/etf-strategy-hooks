// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {CLTaxStrategyHook} from "../src/hooks/CLTaxStrategyHook.sol";
import {ICLPoolManager} from "infinity-core/src/pool-cl/interfaces/ICLPoolManager.sol";

/// @title Deploy CLTaxStrategyHook
/// @notice Deployment script for the ETF Strategy Hook across multiple networks
contract DeployTaxStrategyHook is Script {
    /// @notice Deploy the CLTaxStrategyHook contract
    /// @param poolManager The pool manager address for the target network
    /// @param feeRecipient The address that will receive developer fees
    /// @return hook The deployed hook contract
    function deployHook(
        address poolManager,
        address feeRecipient
    ) public returns (CLTaxStrategyHook hook) {
        require(
            poolManager != address(0),
            "Pool manager cannot be zero address"
        );
        require(
            feeRecipient != address(0),
            "Fee recipient cannot be zero address"
        );

        console.log("Deploying CLTaxStrategyHook...");
        console.log("Pool Manager:", poolManager);
        console.log("Fee Recipient:", feeRecipient);

        hook = new CLTaxStrategyHook(ICLPoolManager(poolManager), feeRecipient);

        console.log("CLTaxStrategyHook deployed at:", address(hook));
        console.log("Hook Fee Percentage:", hook.HOOK_FEE_PERCENTAGE());
        console.log("Strategy Fee Percentage:", hook.STRATEGY_FEE_PERCENTAGE());
        console.log("Fee Denominator:", hook.FEE_DENOMINATOR());

        return hook;
    }

    /// @notice Main deployment function
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Get network-specific pool manager address
        address poolManager = getPoolManagerForCurrentChain();

        // Deploy the hook
        CLTaxStrategyHook hook = deployHook(poolManager, feeRecipient);

        // Log deployment summary
        console.log("=== Deployment Summary ===");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Pool Manager:", poolManager);
        console.log("Fee Recipient:", feeRecipient);
        console.log("CLTaxStrategyHook:", address(hook));
        console.log("========================");

        vm.stopBroadcast();
    }

    /// @notice Get the appropriate pool manager address based on chain ID
    /// @return poolManager The pool manager address for the current chain
    function getPoolManagerForCurrentChain()
        internal
        view
        returns (address poolManager)
    {
        uint256 chainId = block.chainid;

        if (chainId == 56) {
            // BNB Smart Chain Mainnet
            poolManager = vm.envAddress("CL_POOL_MANAGER_MAINNET");
            console.log("Deploying to BNB Smart Chain Mainnet");
        } else if (chainId == 8453) {
            // Base Mainnet
            poolManager = vm.envAddress("CL_POOL_MANAGER_MAINNET");
            console.log("Deploying to Base Mainnet");
        } else if (chainId == 97) {
            // BNB Smart Chain Testnet
            poolManager = vm.envAddress("CL_POOL_MANAGER_TESTNET");
            console.log("Deploying to BNB Smart Chain Testnet");
        } else {
            revert("Unsupported chain ID");
        }

        require(
            poolManager != address(0),
            "Pool manager address not configured"
        );
        return poolManager;
    }
}
