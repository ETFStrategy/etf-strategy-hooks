// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StandardToken
 * @dev Basic ERC20 token with burn and recovery features
 */
contract StandardToken is ERC20, Ownable {
    uint8 private _decimals = 18;

    // Events
    event TokensBurned(address from, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _decimals = 18;
        // No initial mint - tokens will be minted as needed
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Mint token
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Burn tokens from specified address
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Burn tokens from specified address (with allowance)
     */
    function burnFrom(address from, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    /**
     * @dev Recover accidentally sent tokens (owner only)
     */
    function recoverToken(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        require(tokenAddress != address(this), "Cannot recover native token");
        require(tokenAddress != address(0), "Invalid token address");

        ERC20(tokenAddress).transfer(owner(), amount);
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
}
