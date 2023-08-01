// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOffers {

    struct Offer {
        address offererAddress;
        uint256 tokenId;
        address tokenAddress;
        uint256 quantity;
        uint256 price;
        uint256 end;
        uint8 status;
        uint256 rentingPeriod;
        address currency;
    }

    /*
        @notice Accept an offer and sell or rent the requested credits for the offer price.
        @param offerId The id of the offer.
    */
    function acceptOffer(uint256 offerId) external;

    /*
        @notice Cancel offer with given id.
        @dev The sender must be the offerer.
        @param offerId The id of the offer.
    */
    function cancelOffer(uint256 offerId) external;

    /*
        @notice Make a new offer.
        @param creditId The id of the credits for which the sender is making an offer.
        @param tokenAddress The address of the credits smart contract.
        @param totalPrice The total price offered for all the credits.
        @param end The expiry timestamp of the offer.
        @param quantity The amount of tokens.
        @param rentingPeriod If greater than zero the offer is for renting for the given period.
        @param currency The address of the ERC20 token used for payment.
        @return The id of the newly created offer.
    */
    function makeOffer(
        uint256 creditId,
        address tokenAddress,
        uint256 totalPrice,
        uint64 end,
        uint256 quantity,
        uint256 rentingPeriod,
        address currency
    ) external returns(uint256);

    /*
        @notice Returns the detail of the offer with given id.
        @param offerId The id of the target offer.
        @return The details for the offer with given id.
    */
    function getOffer(uint256 offerId) external returns(Offer memory);

    /*
        @notice Emitted when an offer is closed or accepted.
        @param offerId The id of target offer.
        @param newStatus The new status associated to the offer.
    */
    event OfferUpdated(uint256 indexed offerId, uint8 newStatus);

    /*
        @notice Emitted when a new offer is created.
        @param creditId The id of the credits.
        @param totalPrice The price offered for the given credits.
        @param end The timestamp in which the offer will expire.
        @param quantity The number of credits asked.
        @param offerId The id of the offer.
        @param currency The ERC20 address used for payment.
        @param rentingPeriod If greater than zero the offer is for renting for the given period.
    */
    event OfferCreated(
        uint256 indexed creditId,
        uint256 totalPrice,
        uint64 end,
        uint256 quantity,
        uint256 offerId,
        address currency,
        uint256 rentingPeriod
    );

}
