// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./modules/ERC5006.sol";
import "./modules/Fundings.sol";
import "./modules/Bank.sol";
import "./modules/ContractMetadata.sol";
import "./modules/ERC165.sol";

contract Main is
    ERC5006,
    Fundings,
    ContractMetadata,
    ERC165
{

    constructor(
        address owner,
        string memory metadataUri,
        string memory contractMetadataURI
    )
        ContractMetadata(contractMetadataURI)
        ERC1155(metadataUri)
        Roles(owner)
    {}

}
