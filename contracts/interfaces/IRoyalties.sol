// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRoyalties {

    /*
        @notice Updates default royalty bps.
        @dev Can be invoked only by the contract owner.
    */
    function setRoyaltyInfo(uint256 _royaltyBps) external;

    /*
        @notice Returns royalty info for a given token and sale price.
        @param tokenId The id of the target token.
        @param salePrice The sale price for the target token id.
        @return The address of the receiver and the royalty amount.
    */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns(address, uint256);

}
