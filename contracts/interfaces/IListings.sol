// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IListings {

    struct Listing {
        address creatorAddress;
        uint256 creditId;
        address creditsAddress;
        uint256 quantity;
        uint256 pricePerToken;
        uint256 end;
        uint8 status;
        uint256 rentingPeriod;
        address currency;
    }

    /*
        @notice Buy or rent a certain number of credits from the listing with given ID.
        @param listingId The id of the listing.
        @param quantity The quantity of credits that will be purchased or rented.
    */
    function buyFromListing(uint256 listingId, uint256 quantity) external;

    /*
        @notice Cancel a listing.
        @dev The sender must be the same user that created the listing.
        @param listingId The id of the listing that will be canceled.
    */
    function cancelListing(uint256 listingId) external;

    /*
        @notice Users can list a given amount of credits for a fixed price, specifying the starting and ending time
            of the offer.
        @dev The amount of listed credits must be owned by the sender.
        @dev If the renting time is zero the listing is a "sell", otherwise a "rent".
        @dev The currency must implement the ERC20 standard.
        @param creditId The id of the credits that will be listed.
        @param creditsAddress The address of the credits smart contract.
        @param pricePerToken The price of each token.
        @param quantity The amount of token listed.
        @param endTimestamp The timestamp in which the listing will expire.
        @param currency The address of the ERC20 token used for payments.
        @param rentingTime The duration of the renting.
        @return The id of the new listing.
    */
    function createListing(
        uint256 creditId,
        address creditsAddress,
        uint256 pricePerToken,
        uint256 quantity,
        uint256 endTimestamp,
        address currency,
        uint256 rentingPeriod
    ) external returns(uint256);

    /*
        @notice Returns the listing with given ID.
        @return The details of the given listing.
    */
    function getListing(uint256 listingId) external view returns(Listing memory);

    /*
        @notice Emitted when a listing is closed or canceled.
        @param listingId The id of the target listing.
        @param newStatus The new status of the target listing.
    */
    event ListingUpdated(uint256 indexed listingId, uint8 newStatus);

    /*
        @notice Emitted when a new listing is created.
        @param creditId The id of the listed credits.
        @param pricePerToken The price for each token.
        @param quantity The number of listed token.
        @param endTimestamp The timestamp when the listing will end.
        @param rentingTime The renting period.
        @currency The ERC20 token used for payments.
    */
    event ListingCreated(
        uint256 indexed creditId,
        uint256 pricePerToken,
        uint256 quantity,
        uint256 endTimestamp,
        uint256 rentingTime,
        address currency,
        uint256 listingId
    );

}
