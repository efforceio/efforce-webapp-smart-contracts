// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IAccount {
    function isAccountEnabled(address account) external view returns(bool);
}
