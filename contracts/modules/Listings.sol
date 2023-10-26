// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../interfaces/IPurchases.sol";
import "../interfaces/IRoyalties.sol";
import "../interfaces/IERC1155.sol";
import "../helpers/IERC20.sol";
import "../libraries/Errors.sol";
import "./Bank.sol";

abstract contract Listings is IPurchases, Bank {

    struct Listing {
        address creatorAddress;
        uint256 creditId;
        uint256 quantity;
        uint256 pricePerToken;
        bool closed;
    }

    mapping(uint256 => Listing) private idToListing;
    uint256 public nListings;


    modifier listingHasEnoughTokens(uint256 listingId, uint256 quantity) {
        require(idToListing[listingId].quantity - quantity >= 0, Errors.NOT_ENOUGHT_TOKENS);
        _;
    }

    modifier listingIsActive(uint256 listingId) {
        require(
            !idToListing[listingId].closed,
            Errors.NOT_ACTIVE
        );
        _;
    }

    modifier isListingOwner(uint256 listingId, address account) {
        require(idToListing[listingId].creatorAddress == account, Errors.NOT_ALLOWED);
        _;
    }

    /*
        @notice Purchase credits from an active listing. Credits are transferred to the buyers,
            while price deducted by royalties are send to the owner of the listing,
            and royalties to the royalties receiver specifiedn in the credits smart contract.
        @param listingId The id of the target listing.
        @param quantity The amount of token that will be purchased.
    */
    function buyFromListing(uint256 listingId, uint256 quantity)
        listingHasEnoughTokens(listingId, quantity)
        listingIsActive(listingId)
        external
    {
        uint256 total = idToListing[listingId].pricePerToken * quantity;
        (address royaltiesReceiver,uint256 royalties) = IRoyalties(_getCreditsContract()).royaltyInfo(
            idToListing[listingId].creditId,
            total
        );

        IERC20(tokenAddress).transferFrom(msg.sender, idToListing[listingId].creatorAddress, total - royalties);
        IERC20(tokenAddress).transferFrom(msg.sender, royaltiesReceiver, royalties);
        IERC1155(_getCreditsContract()).safeTransferFrom(
            address(this),
            msg.sender,
            idToListing[listingId].creditId,
            quantity,
            ""
        );

        idToListing[listingId].quantity -= quantity;
        emit ListingUpdated(listingId, idToListing[listingId].quantity, idToListing[listingId].pricePerToken, false);
        emit Purchase(
            idToListing[listingId].creditId,
            idToListing[listingId].creatorAddress,
            msg.sender,
            total,
            quantity
        );
    }

    /*
        @notice Close a listing. The remaining credits are transferred back to the owner of the listing.
        @dev The caller must be the owner of the listing.
        @param listingId The id of the target listing.
    */
    function closeListing(uint256 listingId)
        external
        isListingOwner(listingId, msg.sender)
    {
        idToListing[listingId].closed = true;
        IERC1155(_getCreditsContract()).safeTransferFrom(
            address(this),
            msg.sender,
            idToListing[listingId].creditId,
            idToListing[listingId].quantity,
            ""
        );
        emit ListingUpdated(listingId, 0, 0, true);
    }

    /*
        @notice Opens a new listing. The tokens are transferred to the smart contract until they are purchased,
            the listing is closed, or modified.
        @param creditId The id of the credits that will be listed (tokenId).
        @param pricePerToken The price for single tokens.
        @param quantity The amount of tokens that will be listed.
    */
    function createListing(uint256 creditId, uint256 pricePerToken, uint256 quantity)
        external
    {
        IERC1155(_getCreditsContract()).safeTransferFrom(
            msg.sender,
            address(this),
            creditId,
            quantity,
            ""
        );
        idToListing[nListings] = Listing(
            msg.sender,
            creditId,
            quantity,
            pricePerToken,
            false
        );
        nListings++;
        emit CreateListing(msg.sender, creditId, pricePerToken, quantity);
    }

    /*
        @notice Updates the tokens price and the quantity listed. If the new number of credits is higher,
            credits are transferred to the smart contract, otherwise excess tokens are transferred back to the
            listing owner.
        @dev Can be called only by the owner of the listing.
        @param listingId The id of the target listing.
        @param pricePerToken The new price for tokens.
        @param quantity The new quantity of token that is listed.
    */
    function updateListing(uint256 listingId, uint256 pricePerToken, uint256 quantity)
        external
        isListingOwner(listingId, msg.sender)
    {
        if (idToListing[listingId].pricePerToken != pricePerToken) {
            idToListing[listingId].pricePerToken = pricePerToken;
        }
        if (idToListing[listingId].quantity != quantity) {
            if (idToListing[listingId].quantity > quantity) {
                IERC1155(_getCreditsContract()).safeTransferFrom(
                    address(this),
                    msg.sender,
                    idToListing[listingId].creditId,
                    idToListing[listingId].quantity - quantity,
                    ""
                );
            } else {
                IERC1155(_getCreditsContract()).safeTransferFrom(
                    msg.sender,
                    address(this),
                    idToListing[listingId].creditId,
                    quantity - idToListing[listingId].quantity,
                    ""
                );
            }
        }
        emit ListingUpdated(listingId, quantity, pricePerToken, false);
    }

    /*
        @param listingId The id of the target listing.
        @return The listing with given id.
    */
    function getListing(uint256 listingId) external view returns(Listing memory) {
        return idToListing[listingId];
    }

    /*
        @notice Emitted when a listing is updated: after a purchase, a listing closed, and listing update.
        @param listingId The id of the target listing.
        @param quantity The new amount of tokens listed.
        @param pricePerToken The new price for tokens.
        @param closed True of the listing is closed.
    */
    event ListingUpdated(uint256 indexed listingId, uint256 quantity, uint256 pricePerToken, bool closed);

    /*
        @notice Emitted when a new listing is created.
        @param owner The owner of the new listing.
        @param creditId The id of the credits that are listed.
        @param pricePerToken The tokens price.
        @param quantity The amount of tokens that are listed.
    */
    event CreateListing(address indexed owner, uint256 indexed creditId, uint256 pricePerToken, uint256 quantity);

    function _getCreditsContract() internal view virtual returns(address);

}
