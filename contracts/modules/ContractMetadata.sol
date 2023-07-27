// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IContractMetadata.sol";
import "./Fundings.sol";

contract ContractMetadata is IContractMetadata, Fundings {

    string private contractMetadata;

    constructor(
        address owner,
        string memory metadataUri,
        string _contractMetadata
    ) Fundings(owner, metadataUri) {
        contractMetadata = _contractMetadata;
    }

    function setContractURI(
        string calldata _uri
    )
        external
        contractOwner(msg.sender)
        override
    {
        contractMetadata = _uri;
        emit ContractURIUpdated(_uri);
    }

    function contractURI()
        external
        override
        view
        returns(string)
    {
        return contractMetadata;
    }

}
