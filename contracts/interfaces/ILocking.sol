// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

struct Lock {
    uint startTimestamp;
    uint endTimestamp;
    uint amount;
}

interface ILocking {
    function getLastLockForAccount(address account) external view returns(Lock memory);
}
