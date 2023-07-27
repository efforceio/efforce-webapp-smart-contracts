// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC165.sol";

contract ERC165 is IERC165 {

    mapping(bytes4 => bool) private interfaceToSupported;

    constructor() {
        interfaceToSupported[0x01ffc9a7] = true; // ERC-165
        interfaceToSupported[0xd9b67a26] = true; // ERC-1155
        interfaceToSupported[0x0e89341c] = true; // ERC-1155 metadata
        interfaceToSupported[0xc26d96cc] = true; // ERC-5006
        interfaceToSupported[0x2a55205a] = true; // ERC-2981 (royalties)
    }

    function supportsInterface(
        bytes4 interfaceID
    )
        external
        view
        returns(bool)
    {
        return interfaceToSupported[interfaceID];
    }

}
