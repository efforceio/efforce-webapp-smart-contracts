// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

contract ERC165 {

    mapping(bytes4 => bool) private interfaceToSupported;

    constructor() {
        interfaceToSupported[0x01ffc9a7] = true; // ERC-165
        interfaceToSupported[0xd9b67a26] = true; // ERC-1155
        interfaceToSupported[0x0e89341c] = true; // ERC-1155 metadata
        interfaceToSupported[0xc26d96cc] = true; // ERC-5006
        interfaceToSupported[0x2a55205a] = true; // ERC-2981
    }

    /*
        @notice Returns true if the interfaceID is implemented by the smart contract.
        @param interfaceID The target interface id.
        @return True if the target interface id is implemented by the smart contract, false otherwise.
    */
    function supportsInterface(bytes4 interfaceID)
        external
        view
        returns(bool)
    {
        return interfaceToSupported[interfaceID];
    }

}
