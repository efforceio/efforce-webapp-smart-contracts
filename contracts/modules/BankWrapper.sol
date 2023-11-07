// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../interfaces/IBank.sol";

contract BankWrapper {
    address internal immutable tokenAddress;
    address public immutable bankContract;

    constructor(address bankAddress) {
        tokenAddress = IBank(bankAddress).tokenAddress();
        bankContract = bankAddress;
    }
}
