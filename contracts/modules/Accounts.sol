// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IAccounts.sol";
import "../libraries/Errors.sol";
import "./Roles.sol";

abstract contract Accounts is IAccounts, Roles {

    mapping(address => bool) private addressToEnabled;

    modifier accountEnabled(address account) {
        require(addressToEnabled[account], Errors.IS_NOT_ENABLED);
        _;
    }

    modifier notZeroAddress(address account) {
        require(account != address(0), Errors.IS_ZERO_ADDRESS);
        _;
    }

    function updateAccount(
        address account,
        bool enabling
    )
        external
        override
        adminOrOwner(msg.sender)
        notZeroAddress(account)
    {
        addressToEnabled[account] = enabling;
        emit AccountEnabled(account, enabling);
    }

    function isAccountEnabled(
        address account
    )
        external
        view
        override
        returns(bool)
    {
        return addressToEnabled[account];
    }

}
