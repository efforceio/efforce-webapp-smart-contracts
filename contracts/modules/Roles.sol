// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IRoles.sol";
import "../libraries/Errors.sol";

contract Roles is IRoles {

    address public owner;
    mapping(address => bool) private addressToAdmin;
    mapping(address => bool) private addressToManager;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier contractOwner(address account) {
        require(account == owner, Errors.IS_NOT_OWNER);
        _;
    }

    function setAdmin(
        address account,
        bool admin
    )
        external
        override
        contractOwner(msg.sender)
    {
        addressToAdmin[account] = admin;
        emit RoleAssignment(account, 0, admin);
    }

    function setManager(
        address account,
        bool manager
    )
        external
        override
        contractOwner(msg.sender)
    {
        addressToManager[account] = manager;
        emit RoleAssignment(account, 1, manager);
    }

    function setOwner(
        address account
    )
        external
        override
        contractOwner(msg.sender)
    {
        owner = account;
        emit RoleAssignment(account, 2, false);
    }

    function isAdmin(
        address account
    )
        external
        override
        returns(bool)
    {
        return addressToAdmin[account];
    }

    function isManager(
        address account
    )
        external
        override
        returns(bool)
    {
        return addressToManager[account];
    }

}
