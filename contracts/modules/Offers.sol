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

    function cancelOffer(uint256 offerId)
        external
        isOfferOwner(offerId, msg.sender)
    {
        idToOffer[offerId].canceled = true;
        IERC20(tokenAddress).transfer(msg.sender, idToOffer[offerId].price);
        emit OfferUpdated(offerId, 0, 0, true);
    }

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

    function getOffer(uint256 offerId) external view returns(Offer memory) {
        return idToOffer[offerId];
    }

    function _getCreditsContract() internal view virtual returns(address);

    event OfferUpdated(uint256 indexed offerId, uint256 price, uint256 quantity, bool canceled);
    event OfferCreated(uint256 indexed creditId, uint256 totalPrice, uint256 quantity, address offerer);
}
