// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {TaxStrategy} from "../src/contracts/TaxStrategy.sol";

/// @title Deploy TaxStrategy
/// @notice Deployment script for the Tax Strategy contract across multiple networks
contract DeployTaxStrategy is Script {
    /// @notice Deploy the TaxStrategy contract
    /// @return taxStrategy The deployed tax strategy contract
    function deployTaxStrategy() public returns (TaxStrategy taxStrategy) {
        console.log("Deploying TaxStrategy...");

        taxStrategy = new TaxStrategy();

        console.log("TaxStrategy deployed at:", address(taxStrategy));
        console.log("Owner:", taxStrategy.owner());

        return taxStrategy;
    }

    /// @notice Main deployment function
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the tax strategy
        TaxStrategy taxStrategy = deployTaxStrategy();

        // Log deployment summary
        console.log("=== TaxStrategy Deployment Summary ===");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("TaxStrategy:", address(taxStrategy));
        console.log("Owner:", taxStrategy.owner());
        console.log("=====================================");

        vm.stopBroadcast();
    }

    /// @notice Deploy and transfer ownership (for specific use cases)
    /// @param newOwner Address to transfer ownership to after deployment
    function runWithOwnerTransfer(address newOwner) external {
        require(newOwner != address(0), "New owner cannot be zero address");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the tax strategy
        TaxStrategy taxStrategy = deployTaxStrategy();

        // Transfer ownership if specified
        if (newOwner != vm.addr(deployerPrivateKey)) {
            console.log("Transferring ownership to:", newOwner);
            taxStrategy.transferOwnership(newOwner);
        }

        // Log deployment summary
        console.log("=== TaxStrategy Deployment Summary ===");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("TaxStrategy:", address(taxStrategy));
        console.log("Final Owner:", taxStrategy.owner());
        console.log("=====================================");

        vm.stopBroadcast();
    }
}
