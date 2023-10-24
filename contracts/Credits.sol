// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/ERC5006.sol";

contract Credits is ERC5006 {

    constructor(
        string memory metadataUri,
        address _rolesAddress
    )
        ERC1155(metadataUri)
        RolesModifier(_rolesAddress)
    {}
}
