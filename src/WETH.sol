// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/tokens/ERC20.sol"; // use solmate's ERC20

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
}

contract WETH is ERC20, IWETH9 {
    constructor() ERC20("WETH", "WETH", 18) {}

    event Withdraw(address indexed to, uint256 indexed amount);
    event Deposit(address indexed from, uint256 indexed amount);

    // deposit ETH and get WETH
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    // withdraw WETH and get ETH
    function withdraw(uint256 _amount) external {
        _burn(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
        (bool sent, /*bytes memory data*/ ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "transfer eth failed");
    }

    // same as deposit
    receive() external payable {
        deposit();
    }
}
