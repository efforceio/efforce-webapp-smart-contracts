// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IBank {

    /*
        @return The current token address.
    */
    function tokenAddress() external view returns(address);

    function withdraw(address recipient, uint amount) external;
    function withdraw(address recipient, uint amount, address tokenAddress) external;

}
