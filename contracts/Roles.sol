// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./interfaces/IRoles.sol";
import "./libraries/Errors.sol";

contract Roles is IRoles {

    address private owner;
    mapping(address => bool) private addressToAdmin;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier contractOwner(address account) {
        require(account == owner, Errors.NOT_ALLOWED);
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
        emit RoleAssignment(account, false, admin);
    }

    function setOwner(
        address account
    )
        external
        override
        contractOwner(msg.sender)
    {
        owner = account;
        emit RoleAssignment(account, true, false);
    }

    function isAdmin(
        address account
    )
        external
        override
        view
        returns(bool)
    {
        return addressToAdmin[account];
    }

    function getOwner()
        external
        view
        override
        returns(address)
    {
        return owner;
    }

}
