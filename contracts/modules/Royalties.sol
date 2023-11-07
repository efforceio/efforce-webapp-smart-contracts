// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./RolesModifier.sol";
import "../interfaces/IRoyalties.sol";
import "./BankWrapper.sol";

abstract contract Royalties is RolesModifier, IRoyalties, BankWrapper {

    uint256 private royaltyBps;

    /*
        @param _royaltyBps The percentage for royalties.
    */
    constructor(uint256 _royaltyBps) {
        royaltyBps = _royaltyBps;
    }

    /*
        @notice Updates default royalty bps.
        @dev Can be invoked only by the contract owner.
    */
    function setRoyaltyInfo(uint256 _royaltyBps)
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
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns(address, uint256)
    {
        return (bankContract, (salePrice * royaltyBps) / 10_000);
    }

    /*
        @notice Emitted when the royalty bps is updated.
        @param royaltyBps The new royalty bps.
    */
    event RoyaltiesUpdated(uint256 royaltyBps);

}
