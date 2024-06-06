// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../interfaces/IBank.sol";

contract BankWrapper {
    address internal tokenAddress;
    address public bankContract;

    /*
        @notice Set the address of the bank smart contract Address.
        @dev This function must be called only if bankAddress is set to zero address.
        @param bankAddress The address of the bank smart contract.
    */
    function bankWrapperInitializer(address bankAddress) internal {
        tokenAddress = IBank(bankAddress).tokenAddress();
        bankContract = bankAddress;
    }
}
