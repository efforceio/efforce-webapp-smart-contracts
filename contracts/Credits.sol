// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/ERC5006.sol";
import "./modules/ContractMetadata.sol";
import "./modules/ERC165.sol";
import "./modules/Royalties.sol";
import "./modules/ERC5679.sol";

contract Credits is ERC5006, ERC5679, ContractMetadata, ERC165, Royalties {

    constructor(
        string memory metadataUri,
        address _rolesAddress,
        string memory contractMetadataURI,
        uint256 royaltyBps,
        address royaltyReceiver
    )
        ERC1155(metadataUri)
        RolesModifier(_rolesAddress)
        ContractMetadata(contractMetadataURI)
        Royalties(royaltyBps, royaltyReceiver)
    {}
}
