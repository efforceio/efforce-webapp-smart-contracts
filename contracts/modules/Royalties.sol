// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./RolesModifier.sol";

abstract contract Royalties is RolesModifier {

    uint256 private royaltyBps;

    constructor(uint256 _royaltyBps) {
        royaltyBps = _royaltyBps;
    }

    /*
        @notice Updates default royalty bps.
        @dev Can be invoked only by the contract owner.
    */
    function setRoyaltyInfo(
        uint256 _royaltyBps
    )
        external
        adminOrOwner(msg.sender)
    {
        royaltyBps = _royaltyBps;
        emit RoyaltiesUpdated(_royaltyBps);
    }

    /*
        @notice Returns royalty info for a given token and sale price.
        @param tokenId The id of the target token.
        @param salePrice The sale price for the target token id.
        @return The address of the receiver and the royalty amount.
    */
    function royaltyInfo(
        uint256,
        uint256 salePrice
    )
        external
        view
        returns(address, uint256)
    {
        return (address(this), (salePrice * royaltyBps) / 10_000);
    }

    /*
        @notice Emitted when the royalty bps is updated.
        @param royaltyBps The new royalty bps.
    */
    event RoyaltiesUpdated(uint256 royaltyBps);

}
