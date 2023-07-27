// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IContractMetadata {

    /*
        @notice Sets the URI for contract-level metadata.
        @dev Can be invoked by contract owner.
        @param _uri The new contract-level metadata uri.
    */
    function setContractURI(string calldata _uri) external;

    /*
        @notice Returns the contract metadata URI.
        @return The URI for contract-level metadata.
    */
    function contractURI() external view returns(string memory);

    /*
        @notice Emitted when contract metadata are updated.
        @param newUri The new URI.
    */
    event ContractURIUpdated(string newURI);

}
