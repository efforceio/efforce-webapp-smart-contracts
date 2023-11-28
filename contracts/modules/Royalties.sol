// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./RolesModifier.sol";
import "../interfaces/IRoyalties.sol";

abstract contract Royalties is RolesModifier, IRoyalties {

    uint private royaltyBps;
    address public receiver;

    /*
        @param _royaltyBps The percentage for royalties.
    */
    constructor(uint _royaltyBps, address _receiver) {
        royaltyBps = _royaltyBps;
        receiver = _receiver;
    }

    /*
        @notice Updates default royalty bps.
        @dev Can be invoked only by the contract owner.
    */
    function setRoyaltyInfo(uint _royaltyBps)
        external
        adminOrOwner(msg.sender)
    {
        royaltyBps = _royaltyBps;
        emit RoyaltiesUpdated(_royaltyBps);
    }

    /*
        @notice Updates the receiver of royalties.
        @dev Can be called only by contract owner or admins.
        @param _receiver The new receiver.
    */
    function setRoyaltyReceiver(address _receiver)
        external
        adminOrOwner(msg.sender)
    {
        receiver = _receiver;
        emit RoyaltiesReceiverUpdated(_receiver);
    }

    /*
        @notice Returns royalty info for a given token and sale price.
        @param tokenId The id of the target token.
        @param salePrice The sale price for the target token id.
        @return The address of the receiver and the royalty amount.
    */
    function royaltyInfo(uint, uint salePrice)
        external
        view
        override
        returns(address, uint)
    {
        return (receiver, (salePrice * royaltyBps) / 10_000);
    }

    /*
        @notice Emitted when the royalty bps is updated.
        @param royaltyBps The new royalty bps.
    */
    event RoyaltiesUpdated(uint royaltyBps);

    /*
        @notice Emitted when the royalty receiver is updated.
        @param receiver The new receiver address.
    */
    event RoyaltiesReceiverUpdated(address receiver);

}
