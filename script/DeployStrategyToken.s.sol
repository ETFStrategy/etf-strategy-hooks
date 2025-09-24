// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {StrategyTokenSample} from "../src/contracts/StrategyTokenSample.sol";

/// @title Deploy StrategyTokenSample
/// @notice Deployment script for the Strategy Token across multiple networks
contract DeployStrategyToken is Script {
    /// @notice Deploy the StrategyTokenSample contract
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param etfTreasury The treasury address that will receive fees
    /// @return token The deployed token contract
    function deployToken(
        string memory name,
        string memory symbol,
        address etfTreasury
    ) public returns (StrategyTokenSample token) {
        require(etfTreasury != address(0), "Treasury cannot be zero address");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");

        console.log("Deploying StrategyTokenSample...");
        console.log("Token Name:", name);
        console.log("Token Symbol:", symbol);
        console.log("ETF Treasury:", etfTreasury);

        token = new StrategyTokenSample(name, symbol, etfTreasury);

        console.log("StrategyTokenSample deployed at:", address(token));
        console.log("Token Decimals:", token.decimals());
        console.log("Max Supply:", token.MAX_SUPPLY());
        console.log("Total Supply:", token.totalSupply());
        console.log("Owner:", token.owner());

        return token;
    }

    /// @notice Main deployment function
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get token configuration from environment or use defaults
        string memory tokenName = vm.envOr(
            "TOKEN_NAME",
            string("Strategy Token")
        );
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("STG"));
        address etfTreasury = vm.envAddress("ETF_TREASURY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the token
        StrategyTokenSample token = deployToken(
            tokenName,
            tokenSymbol,
            etfTreasury
        );

        // Log deployment summary
        console.log("=== StrategyToken Deployment Summary ===");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Token Name:", tokenName);
        console.log("Token Symbol:", tokenSymbol);
        console.log("ETF Treasury:", etfTreasury);
        console.log("StrategyTokenSample:", address(token));
        console.log("Initial Supply Minted To:", token.owner());
        console.log("========================================");

        vm.stopBroadcast();
    }

    /// @notice Deploy with custom parameters (for testing or specific deployments)
    /// @param name Custom token name
    /// @param symbol Custom token symbol
    /// @param treasury Custom treasury address
    function runWithParams(
        string memory name,
        string memory symbol,
        address treasury
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the token with custom parameters
        StrategyTokenSample token = deployToken(name, symbol, treasury);

        // Log deployment summary
        console.log("=== Custom StrategyToken Deployment ===");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("StrategyTokenSample:", address(token));
        console.log("======================================");

        vm.stopBroadcast();
    }
}
