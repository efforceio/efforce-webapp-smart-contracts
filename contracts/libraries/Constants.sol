// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Constants {

    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant public ERC1155_ACCEPTED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 constant public ERC1155_BATCH_ACCEPTED = 0xbc197c81;

}
