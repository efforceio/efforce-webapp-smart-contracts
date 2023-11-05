// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../helpers/IERC20.sol";
import "./RolesModifier.sol";

abstract contract Bank is RolesModifier {

    address public immutable tokenAddress;
    uint256 internal blockedERC20;

    /*
        @param _tokenAddress The address of the ERC20 token.
    */
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    /*
        @notice Raises an error if the available balance in the smart contract is not enough to cover the
            requested amount.
        @param amount The amount of token to be withdrawn from the smart contract.
    */
    modifier availableBalance(uint256 amount) {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) - blockedERC20 >= amount,
            Errors.BALANCE_NOT_AVAILABLE
        );
        _;
    }

    /*
        @notice Transfers the amount of ERC20 tokens from the smart contract to the recipient address.
        @dev Can be invoked only by the contract owner or admins.
        @param recipient The address that will receive the ERC20 tokens.
        @param amount The amount of ERC20 tokens that will be transferred.
    */
    function withdraw(
        address recipient,
        uint256 amount
    )
        external
        adminOrOwner(msg.sender)
        availableBalance(amount)
    {
        IERC20(tokenAddress).transfer(recipient, amount);
        emit Withdrawal(recipient, amount);
    }

    /*
        @notice Emitted when a withdrawal is approved.
        @param tokenAddress The ERC20 token which is transferred.
        @param recipient The address that received the ERC20 tokens.
        @param amount The amount of ERC20 token which are transferred.
    */
    event Withdrawal(address indexed recipient, uint256 amount);

    /*
        @notice Emitted when the amount of locked funds is updated.
    */
    event FundsLockedUpdated(uint256 lockedFunds);
}
