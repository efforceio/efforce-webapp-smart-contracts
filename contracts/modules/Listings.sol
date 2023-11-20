// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../interfaces/IPurchases.sol";
import "../interfaces/IRoyalties.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/ICredits.sol";
import "../helpers/IERC20.sol";
import "../libraries/Errors.sol";
import "./BankWrapper.sol";

abstract contract Listings is IPurchases, BankWrapper {

    struct Listing {
        address creatorAddress;
        uint256 creditId;
        uint256 quantity;
        uint256 pricePerToken;
        bool closed;
    }

    mapping(uint256 => Listing) private idToListing;
    uint256 public nListings;


    /*
        @notice Throws an error if the listing has not enough credits.
        @param listingId The id of the listing.
        @param quantity The quantity amount.
    */
    modifier listingHasEnoughTokens(uint256 listingId, uint256 quantity) {
        require(idToListing[listingId].quantity - quantity >= 0, Errors.NOT_ENOUGHT_TOKENS);
        _;
    }

    /*
        @notice throws an error if the listing is closed.
        @param listingId The id of the listing.
    */
    modifier listingIsActive(uint256 listingId) {
        require(!idToListing[listingId].closed, Errors.NOT_ACTIVE);
        _;
    }

    /*
        @notice Throws an error if the account is not the owner of the listing.
        @param listingId The id of the listing.
        @param account The target account.
    */
    modifier isListingOwner(uint256 listingId, address account) {
        require(idToListing[listingId].creatorAddress == account, Errors.NOT_ALLOWED);
        _;
    }

    /*
        @notice Purchase credits from an active listing. Credits are transferred to the buyers,
            while price deducted by royalties are send to the owner of the listing,
            and royalties to the royalties receiver specified in the credits smart contract.
        @param listingId The id of the target listing.
        @param quantity The amount of token that will be purchased.
    */
    function buyFromListing(uint256 listingId, uint256 quantity) external {
        _buyFromListing(listingId, quantity);
    }

    /*
        @notice Purchase credits from an active listings. Credits are transferred to the buyers,
            while price deducted by royalties are send to the owner of the listing,
            and royalties to the royalties receiver specified in the credits smart contract.
            The purchase action is repeated for each id and quantity.
        @param ids The ids of the target listing.
        @param quantities The amounts of token that will be purchased.
    */
    function buyFromListingBatch(uint256[] calldata ids, uint256[] calldata quantities) external {
        for (uint256 i = 0; i < ids.length; i++) {
            _buyFromListing(ids[i], quantities[i]);
        }
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
        emit ListingClosed(
            listingId,
            ICredits(_getCreditsContract()).getVintage(idToListing[listingId].creditId).projectId,
            false
        );
    }

    /*
        @notice Opens a new listing. The tokens are transferred to the smart contract until they are purchased,
            the listing is closed, or modified.
        @param creditId The id of the credits that will be listed (tokenId).
        @param pricePerToken The price for single tokens.
        @param quantity The amount of tokens that will be listed.
    */
    function createListing(uint256 creditId, uint256 pricePerToken, uint256 quantity) external {
        _positiveAmount(quantity);
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

        emit CreateListing(
            nListings,
            msg.sender,
            ICredits(_getCreditsContract()).getVintage(creditId).projectId,
            creditId,
            pricePerToken,
            quantity
        );

        nListings++;
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
        _positiveAmount(quantity);
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
            idToListing[listingId].quantity = quantity;
        }
        emit ListingUpdated(
            listingId,
            ICredits(_getCreditsContract()).getVintage(idToListing[listingId].creditId).projectId,
            quantity,
            pricePerToken
        );
    }

    /*
        @param listingId The id of the target listing.
        @return The listing with given id.
    */
    function getListing(uint256 listingId) external view returns(Listing memory) {
        return idToListing[listingId];
    }

    function _buyFromListing(uint256 listingId, uint256 quantity)
        listingHasEnoughTokens(listingId, quantity)
        listingIsActive(listingId)
        private
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

        if (idToListing[listingId].quantity == 0) {
            idToListing[listingId].closed = true;
            emit ListingClosed(
                listingId,
                ICredits(_getCreditsContract()).getVintage(idToListing[listingId].creditId).projectId,
                true
            );
        }

        emit ListingUpdated(
            listingId,
            ICredits(_getCreditsContract()).getVintage(idToListing[listingId].creditId).projectId,
            idToListing[listingId].quantity,
            idToListing[listingId].pricePerToken
        );
        emit Purchase(
            idToListing[listingId].creditId,
            ICredits(_getCreditsContract()).getVintage(idToListing[listingId].creditId).projectId,
            idToListing[listingId].creatorAddress,
            msg.sender,
            total,
            quantity
        );
    }

    function _getCreditsContract() internal view virtual returns(address);
    function _positiveAmount(uint256 amount) internal pure virtual;

    /*
        @notice Emitted when a listing is updated: after a purchase and listing update.
        @param listingId The id of the target listing.
        @param projectId The project id of the vintages (credits).
        @param quantity The new amount of tokens listed.
        @param pricePerToken The new price for tokens.
    */
    event ListingUpdated(uint256 indexed listingId, uint256 indexed projectId, uint256 quantity, uint256 pricePerToken);

    /*
        @notice Emitted when a listing is closed.
        @param listingId The id of the listing.
        @param projectId The project id of the vintages (credits).
        @param funded Set to true if the listing is closed after all the credits are sold, false otherwise.
    */
    event ListingClosed(uint256 indexed listingId, uint256 indexed projectId, bool indexed funded);

    /*
        @notice Emitted when a new listing is created.
        @param owner The owner of the new listing.
        @param projectId The project id of the vintages (credits).
        @param creditId The id of the credits that are listed.
        @param pricePerToken The tokens price.
        @param quantity The amount of tokens that are listed.
    */
    event CreateListing(
        uint256 id,
        address indexed owner,
        uint256 indexed projectId,
        uint256 indexed creditId,
        uint256 pricePerToken,
        uint256 quantity
    );

}
