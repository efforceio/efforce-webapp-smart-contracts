// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBank {

    /*
        @notice Transfers the amount of ERC20 tokens from the smart contract to the recipient address.
        @dev Can be invoked only by the contract owner.
        @param tokenAddress The ERC20 to be transferred.
        @param recipient The address that will receive the ERC20 tokens.
        @param amount The amount of ERC20 tokens that will be transferred.
    */
    function withdraw(address tokenAddress, address recipient, uint256 amount) external;

    /*
        @notice Emitted when a withdrawal is approved.
        @param tokenAddress The ERC20 token which is transferred.
        @param recipient The address that received the ERC20 tokens.
        @param amount The amount of ERC20 token which are transferred.
    */
    event Withdrawal(address indexed tokenAddress, address indexed recipient, uint256 amount);
}
