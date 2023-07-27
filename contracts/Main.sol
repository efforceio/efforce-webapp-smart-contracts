// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./modules/ERC5006.sol";
import "./modules/Fundings.sol";
import "./modules/Bank.sol";
import "./modules/ContractMetadata.sol";
import "./modules/ERC165.sol";
import "./modules/Royalties.sol";

contract Main is
    ERC5006,
    Fundings,
    ContractMetadata,
    ERC165,
    Royalties
{

    constructor(
        address owner,
        string memory metadataUri,
        string memory contractMetadataURI,
        uint256 royaltyBps
    )
        ContractMetadata(contractMetadataURI)
        ERC1155(metadataUri)
        Roles(owner)
        Royalties(royaltyBps)
    {}

}
