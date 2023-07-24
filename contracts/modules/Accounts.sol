// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IAccounts.sol";
import "./Roles.sol";

contract Accounts is IAccounts, Roles {

    mapping(address => bool) private addressToEnabled;

    constructor(address owner) Roles(owner) {}

    function updateAccount(
        address account,
        bool enabling
    )
        external
        override
        adminOrOwner(msg.sender)
    {
        addressToEnabled[account] = enabling;
        emit AccountEnabled(account, enabling);
    }

    function isAccountEnabled(
        address account
    )
        external
        override
        returns(bool)
    {
        return addressToEnabled[account];
    }

}
