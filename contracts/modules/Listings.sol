// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IListings.sol";
import "../interfaces/IPurchase.sol";
import "../interfaces/IRoyalties.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC5006.sol";
import "../libraries/Errors.sol";
import "../helpers/IERC20.sol";

contract Listings is IListings, IPurchase {

    mapping(uint256 => Listing) private idToListing;
    uint256 public nListings;

    constructor() {
        nListings = 0;
    }

    modifier availableCredits(uint256 listingId, uint256 amount) {
        require(idToListing[listingId].quantity >= amount, Errors.INSUFFICIENT_BALANCE);
        _;
    }

    modifier listingIsActive(uint256 listingId) {
        require(idToListing[listingId].status < 2, Errors.NOT_EXISTS);
        _;
    }

    modifier isOwner(uint256 listingId, address account) {
        require(idToListing[listingId].creatorAddress == account, Errors.NOT_ALLOWED);
        _;
    }

    modifier hasEnoughTokens(uint256 creditsId, address creditsAddress, address owner) {
        require(IERC1155(creditsAddress).balanceOf(owner, creditsId), Errors.CREDITS_NOT_AVAILABLE);
        _;
    }

    function buyFromListing(
        uint256 listingId,
        uint256 quantity
    )
        external
        override
        availableCredits(listingId, quantity)
        listingIsActive(listingId)
    {
        address royaltiesReceiver;
        uint256 royalties;
        uint price = idToListing[listingId].pricePerToken * quantity;

        (royaltiesReceiver, royalties) = IRoyalties(idToListing[listingId]).royaltyInfo(
            idToListing[listingId].creditId,
            idToListing[listingId].creditId.pricePerToken * quantity
        );

        IERC20(idToListing[listingId].currency).transferFrom(msg.sender, royaltiesReceiver, royalties);
        IERC20(idToListing[listingId].currency).transferFrom(
            msg.sender,
            price - royaltiesReceiver,
            royalties
        );

        if (idToListing[listingId].rentingPeriod == 0) {
            IERC1155(idToListing[listingId].creditsAddress).safeTransferFrom(
                idToListing[listingId].creatorAddress,
                msg.sender,
                idToListing[listingId].creditId,
                quantity,
                0x00
            );

            emit PurchaseCompleted(
                idToListing[listingId].creditId,
                idToListing[listingId].creatorAddress,
                msg.sender,
                price,
                quantity,
                idToListing[listingId].currency,
                royalties,
                royaltiesReceiver
            );
        } else {
            uint256 expireTimestamp = block.timestamp + idToListing[listingId].rentingPeriod;

            IERC5006(idToListing[listingId].creditsAddress).createUserRecord(
                idToListing[listingId].creatorAddress,
                msg.sender,
                idToListing[listingId].creditId,
                quantity,
                expireTimestamp
            );

            emit LendingCompleted(
                idToListing[listingId].creditId,
                idToListing[listingId].creatorAddress,
                msg.sender,
                price,
                quantity,
                idToListing[listingId].currency,
                expireTimestamp,
                royalties,
                royaltiesReceiver
            );
        }

        idToListing[listingId].quantity -= quantity;

        if (idToListing[listingId].quantity == 0) {
            idToListing[listingId].status = 1;
            emit ListingUpdated(listingId, 1);
        }
    }

    function cancelListing(
        uint256 listingId
    )
        external
        override
        listingIsActive(listingId)
        isOwner(listingId, msg.sender)
    {
        idToListing[listingId].status = 2;
        ListingUpdated(listingId, 2);
    }

    function createListing(
        uint256 creditId,
        address creditsAddress,
        uint256 pricePerToken,
        uint256 quantity,
        uint256 endTimestamp,
        address currency,
        uint256 rentingPeriod
    )
        external
        override
        hasEnoughTokens(creditId, creditsAddress, msg.sender)
    {
        nListings++;

        idToListing[nListings] = Listings(
            msg.sender,
            creditId,
            creditsAddress,
            quantity,
            pricePerToken,
            endTimestamp,
            0,
            rentingPeriod,
            currency
        );

        emit ListingCreated(
            creditId,
            pricePerToken,
            quantity,
            endTimestamp,
            rentingTime,
            currency
        );
    }

    function getListing(
        uint256 listingId
    )
        external
        override
        view
        returns(Listing)
    {
        return idToListing[listingId];
    }

}
