// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../helpers/IERC20.sol";
import "./RolesModifier.sol";

abstract contract Bank is RolesModifier {

    modifier availableBalance(address tokenAddress, uint256 amount) {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) - _blockedAmountForToken(tokenAddress) >= amount,
            Errors.BALANCE_NOT_AVAILABLE
        );
        _;
    }

    /*
        @notice Transfers the amount of ERC20 tokens from the smart contract to the recipient address.
        @dev Can be invoked only by the contract owner or admins.
        @param tokenAddress The ERC20 to be transferred.
        @param recipient The address that will receive the ERC20 tokens.
        @param amount The amount of ERC20 tokens that will be transferred.
    */
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    )
        external
        adminOrOwner(msg.sender)
        availableBalance(tokenAddress, amount)
    {
        IERC20(tokenAddress).transfer(recipient, amount);
        emit Withdrawal(tokenAddress, recipient, amount);
    }


    function _blockedAmountForToken(
        address token
    )
        internal
        virtual
        view
        returns(uint256);

    /*
        @notice Emitted when a withdrawal is approved.
        @param tokenAddress The ERC20 token which is transferred.
        @param recipient The address that received the ERC20 tokens.
        @param amount The amount of ERC20 token which are transferred.
    */
    event Withdrawal(address indexed tokenAddress, address indexed recipient, uint256 amount);
}
