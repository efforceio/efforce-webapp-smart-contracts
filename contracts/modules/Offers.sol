// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IPurchases.sol";
import "../interfaces/IRoyalties.sol";
import "./Bank.sol";
import "../libraries/Errors.sol";
import "../helpers/IERC20.sol";
import "../interfaces/IERC1155.sol";

abstract contract Offers is IPurchases, Bank {

    struct Offer {
        address offererAddress;
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        bool canceled;
    }

    mapping (uint256 => Offer) private idToOffer;
    uint256 public nOffers;

    modifier offerActive(uint256 offerId) {
        require(!idToOffer[offerId].canceled, Errors.NOT_ACTIVE);
        _;
    }

    modifier isOfferOwner(uint256 offerId, address account) {
        require(idToOffer[offerId].offererAddress == account, Errors.NOT_ALLOWED);
        _;
    }

    /*
        @notice Accepts an offer made for a token. All the token specified in the are purchased and transferred
            to the offerer. The offered price is transferred to the caller of the transaction deducted by royalties,
            that will be sent to the royalties receiver. The offer is then closed.
        @param offerId The id of the offer.
    */
    function acceptOffer(uint256 offerId)
        external
        offerActive(offerId)
    {
        (address royaltiesReceiver,uint256 royalties) = IRoyalties(_getCreditsContract()).royaltyInfo(
            idToOffer[offerId].tokenId,
            idToOffer[offerId].price
        );
        IERC1155(_getCreditsContract()).safeTransferFrom(
            msg.sender,
            idToOffer[offerId].offererAddress,
            idToOffer[offerId].tokenId,
            idToOffer[offerId].quantity,
            ""
        );
        IERC20(tokenAddress).transfer(msg.sender, idToOffer[offerId].price - royalties);
        IERC20(tokenAddress).transfer(royaltiesReceiver, royalties);
        idToOffer[offerId].canceled = true;
        emit OfferUpdated(offerId, 0, 0, true);
        emit Purchase(
            idToOffer[offerId].tokenId,
            msg.sender,
            idToOffer[offerId].offererAddress,
            idToOffer[offerId].price,
            idToOffer[offerId].quantity
        );
    }

    /*
        @notice Closes an existing offer. The offered price is transferred back to the owner of the offer.
        @dev Can be called only by the owner of the offer.
        @param offerId The id of the offer.
    */
    function cancelOffer(uint256 offerId)
        external
        isOfferOwner(offerId, msg.sender)
    {
        idToOffer[offerId].canceled = true;
        IERC20(tokenAddress).transfer(msg.sender, idToOffer[offerId].price);
        emit OfferUpdated(offerId, 0, 0, true);
    }

    /*
        @notice Opens a new offer. Proposed price is transferred from the offerer to the smart contract.
        @param tokenId The id of the tokens for which the offer is opened.
        @param totalPrice The price offered for the credits.
        @param quantity The amount of credits that will be purchased.
    */
    function makeOffer(uint256 tokenId, uint256 totalPrice, uint256 quantity) external {
        idToOffer[nOffers] = Offer(
            msg.sender,
            tokenId,
            quantity,
            totalPrice,
            false
        );
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), totalPrice);
        emit OfferCreated(tokenId, totalPrice, quantity, msg.sender);
    }

    /*
        @notice Updates the offer with given id. If the new total price is higher than the current one, the difference
            is transferred to the smart contract, otherwise the excess is transferred back to the caller.
        @dev The caller must be the owner of the offer.
        @param offerId The id of the target offer.
        @param totalPrice The new total price.
        @param quantity The new quantity.
    */
    function updateOffer(uint256 offerId, uint256 totalPrice, uint256 quantity)
        external
        isOfferOwner(offerId, msg.sender)
    {
        if (idToOffer[offerId].price != totalPrice) {
            if (idToOffer[offerId].price > totalPrice) {
                IERC20(tokenAddress).transfer(msg.sender, idToOffer[offerId].price - totalPrice);
            } else {
                IERC20(tokenAddress).transferFrom(msg.sender, address(this), totalPrice - idToOffer[offerId].price);
            }
            idToOffer[offerId].price = totalPrice;
        }
        if (idToOffer[offerId].quantity != quantity) {
            idToOffer[offerId].quantity = quantity;
        }
        emit OfferUpdated(offerId, totalPrice, quantity, false);
    }

    /*
        @param offerId.
        @return The offer for the given id.
    */
    function getOffer(uint256 offerId) external view returns(Offer memory) {
        return idToOffer[offerId];
    }

    function _getCreditsContract() internal view virtual returns(address);

    /*
        @notice Emitted when an offer is updated, closed, or accepted.
        @param offerId The id of the target offer.
        @param price The new price.
        @param quantity The new quantity.
        @param canceled True if the offer is cancelled or accepted.
    */
    event OfferUpdated(uint256 indexed offerId, uint256 price, uint256 quantity, bool canceled);

    /*
        @notice Emitted when a new offer is created.
        @param creditId The id of the credits for which the offer is opened.
        @param totalPrice The offered price.
        @param quantity The required amount of credits.
        @param offerer The account that opened the offer.
    */
    event OfferCreated(uint256 indexed creditId, uint256 totalPrice, uint256 quantity, address offerer);
}
