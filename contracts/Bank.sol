// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./helpers/IERC20.sol";
import "./modules/RolesModifier.sol";

contract Bank is RolesModifier {

    address public immutable tokenAddress;

    /*
        @param _tokenAddress The address of the ERC20 token.
    */
    constructor(address _tokenAddress, address _rolesAddress) {
        rolesAddress = _rolesAddress;
        tokenAddress = _tokenAddress;
    }

    /*
        @notice Transfers the amount of ERC20 tokens from the `tokenAddress` smart contract to the recipient address.
        @dev Can be invoked only by the contract owner or admins.
        @param recipient The address that will receive the ERC20 tokens.
        @param amount The amount of ERC20 tokens that will be transferred.
    */
    function withdraw(address recipient, uint256 amount) external {
        _withdraw(recipient, amount, tokenAddress);
    }

    /*
        @notice Transfers the amount of ERC20 tokens from the `tokenAddress` smart contract to the recipient address.
        @dev Can be invoked only by the contract owner or admins.
        @param recipient The address that will receive the ERC20 tokens.
        @param amount The amount of ERC20 tokens that will be transferred.
        @param _tokenAddress The address of the ERC20 smart contract.
    */
    function withdraw(address recipient, uint256 amount, address _tokenAddress) external {
        _withdraw(recipient, amount, _tokenAddress);
    }

    function _withdraw(address recipient, uint256 amount, address _tokenAddress)
        internal
        adminOrOwner(msg.sender)
    {
        IERC20(_tokenAddress).transfer(recipient, amount);
        emit Withdrawal(recipient, amount, _tokenAddress);
    }

    /*
        @notice Emitted when a withdrawal is approved.
        @param recipient The address that received the ERC20 tokens.
        @param amount The amount of ERC20 token which are transferred.
        @param tokenAddress The address of the ERC20 token.
    */
    event Withdrawal(address indexed recipient, uint256 amount, address indexed tokenAddress);
}
