// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface ITaxStrategy {
    function addFees() external payable;
}

/**
 * @title TaxStrategy
 * @dev Contract to receive and manage fees collected from hooks
 */
contract TaxStrategy is Ownable {
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Recover accidentally sent tokens (owner only)
     */
    function recoverToken(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot recover native token");
        require(tokenAddress != address(0), "Invalid token address");

        IERC20(tokenAddress).transfer(owner(), amount);
    }

    /**
     * @dev Recover accidentally sent ETH (owner only)
     */
    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to recover");

        payable(owner()).transfer(balance);
    }

    /**
     * @dev Allow contract to receive ETH
     */
    receive() external payable {}

    /**
     * @dev Add Fees: method to other contracts to send ETH native
     */
    function addFees() external payable {
        require(msg.value > 0, "No ETH sent");
    }
}
