// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/ERC5006.sol";
import "./modules/Fundings.sol";
import "./modules/ContractMetadata.sol";
import "./modules/ERC165.sol";
import "./modules/Royalties.sol";

contract Credits is ERC5006, Fundings, ContractMetadata, ERC165, Royalties {

    constructor(
        string memory metadataUri,
        address _rolesAddress,
        string memory contractMetadataURI,
        uint256 royaltyBps
    )
        ERC1155(metadataUri)
        RolesModifier(_rolesAddress)
        ContractMetadata(contractMetadataURI)
        Royalties(royaltyBps)
    {}
}
