// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAccounts {

    /*
        @notice If enabling is true, the input account is enabled to send and receive credits, otherwise their right is revoked.
        @dev Can be invoked only by admins and the contract owner.
        @dev If the input account already has some credits, it cannot be disabled.
        @param account The target account.
        @param enabling If true, the target account is enabled to receive the credits, otherwise it will be disabled.
    */
    function updateAccount(address account, bool enabling) external;

    /*
        @notice Used to check if the account's address is enabled to receive credits.
        @param account The target account.
        @return True if the target account is enabled, false otherwise.
    */
    function isAccountEnabled(address account) external returns(bool);

    /*
        @notice Emitted when an account is enabled or disabled.
    */
    event AccountEnabled(address indexed account, bool enabled);

}
