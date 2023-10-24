// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../libraries/Errors.sol";
import "./RolesModifier.sol";

abstract contract Accounts is RolesModifier {

    mapping(address => bool) private addressToEnabled;

    /*
        @notice Raises an error if the input account is not enabled for tradings.
        @param account The target account.
    */
    modifier accountEnabled(address account) {
        require(addressToEnabled[account], Errors.IS_NOT_ENABLED);
        _;
    }

    /*
        @notice Raises an error if the input account is the zero address.
        @param account The target account.
    */
    modifier notZeroAddress(address account) {
        require(account != address(0), Errors.IS_ZERO_ADDRESS);
        _;
    }

    /*
        @notice If enabling is true, the input account is enabled to send and receive credits,
            otherwise their right is revoked.
        @dev Can be invoked only by admins and the contract owner.
        @param account The target account.
        @param enabling If true, the target account is enabled to receive the credits, otherwise it will be disabled.
    */
    function updateAccount(
        address account,
        bool enabling
    )
        external
        adminOrOwner(msg.sender)
        notZeroAddress(account)
    {
        addressToEnabled[account] = enabling;
        emit AccountEnabled(account, enabling);
    }

    /*
        @notice Used to check if the account's address is enabled to receive credits.
        @param account The target account.
        @return True if the target account is enabled, false otherwise.
    */
    function isAccountEnabled(
        address account
    )
        external
        view
        returns(bool)
    {
        return addressToEnabled[account];
    }

    /*
        @notice Emitted when an account is enabled or disabled.
        @param account The target account.
        @param enabled True if the target account is enabled, false otherwise.
    */
    event AccountEnabled(address indexed account, bool enabled);

}
