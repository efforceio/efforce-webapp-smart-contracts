// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./RolesModifier.sol";

abstract contract ContractMetadata is RolesModifier {

    string private contractMetadataURI;

    /*
        @param _contractMetadataURI The url to the contract metadata
    */
    constructor(string memory _contractMetadataURI) {
        contractMetadataURI = _contractMetadataURI;
    }

    /*
        @notice Sets the URI for contract-level metadata.
        @dev Can be invoked by admins or contract owner.
        @param _uri The new contract-level metadata uri.
    */
    function setContractURI(string calldata _uri)
        external
        adminOrOwner(msg.sender)
    {
        contractMetadataURI = _uri;
        emit ContractURIUpdated(_uri);
    }

    /*
        @return The URI for contract-level metadata.
    */
    function contractURI()
        external
        view
        returns(string memory)
    {
        return contractMetadataURI;
    }

    /*
        @notice Emitted when contract metadata are updated.
        @param newUri The new URI.
    */
    event ContractURIUpdated(string newURI);

}
