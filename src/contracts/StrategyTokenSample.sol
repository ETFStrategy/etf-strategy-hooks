// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StrategyTokenSample is ERC20, Ownable {
    uint8 private constant _decimals = 18;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** _decimals; // 1 billion tokens

    event TokensBurned(address from, uint256 amount);
    event UpdatedEtfTreasury(address newTreasury);

    address public etfTreasury;

    constructor(
        string memory name_,
        string memory symbol_,
        address _etfTreasury
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);

        require(_etfTreasury != address(0), "Invalid treasury address");
        etfTreasury = _etfTreasury;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Burn tokens from specified address
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Update the ETF treasury address
     * @param _etfTreasury New treasury address
     */
    function setEtfTreasury(address _etfTreasury) external onlyOwner {
        require(_etfTreasury != address(0), "Invalid address");
        etfTreasury = _etfTreasury;
        emit UpdatedEtfTreasury(_etfTreasury);
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
     * @dev Recover accidentally sent ETH (owner only)
     */
    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to recover");

        payable(owner()).transfer(balance);
    }

    /**
     * @dev Add Fees: method to treasury contracts to send ETH native
     */
    function addFees() external payable {
        require(msg.value > 0, "No ETH sent");
        // Transfer ETH to the ETF treasury
        (bool success, ) = etfTreasury.call{value: msg.value}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @dev Allow contract to receive ETH
     */
    receive() external payable {}
}
