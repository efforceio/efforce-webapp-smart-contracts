// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IERC20 {

    function balanceOf(address who) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function supportsInterface(bytes4 interfaceID) external view returns(bool);

}
