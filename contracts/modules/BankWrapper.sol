// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../interfaces/IBank.sol";

contract BankWrapper {
    address internal tokenAddress;
    address public bankContract;
}
