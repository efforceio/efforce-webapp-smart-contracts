// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IContractMetadata.sol";
import "./Roles.sol";

abstract contract ContractMetadata is IContractMetadata, Roles {

    string private contractMetadataURI;

    constructor(
        string memory _contractMetadataURI
    ) {
        contractMetadataURI = _contractMetadataURI;
    }

    function setContractURI(
        string calldata _uri
    )
        external
        contractOwner(msg.sender)
        override
    {
        contractMetadataURI = _uri;
        emit ContractURIUpdated(_uri);
    }

    function contractURI()
        external
        override
        view
        returns(string memory)
    {
        return contractMetadataURI;
    }

}
