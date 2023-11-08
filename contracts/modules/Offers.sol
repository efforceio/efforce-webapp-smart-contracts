// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IPurchases.sol";
import "../interfaces/IRoyalties.sol";
import "./BankWrapper.sol";
import "../libraries/Errors.sol";
import "../helpers/IERC20.sol";
import "../interfaces/IERC1155.sol";

abstract contract Offers is IPurchases, BankWrapper {

    struct Offer {
        address offererAddress;
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        bool closed;
    }

    mapping (uint256 => Offer) private idToOffer;
    uint256 public nOffers;

    /*
        @notice Throws an error if the offerId is canceled.
        @param offerId The id of the target offer.
    */
    modifier offerActive(uint256 offerId) {
        require(!idToOffer[offerId].closed, Errors.NOT_ACTIVE);
        _;
    }

    /*
        @notice Throws an error if the offer has not enough credits.
        @param offerId The id of the offer.
        @param quantity The quantity amount.
    */
    modifier offerHasEnoughTokens(uint256 offerId, uint256 quantity) {
        require(idToOffer[offerId].quantity - quantity >= 0, Errors.NOT_ENOUGHT_TOKENS);
        _;
    }

    /*
        @notice Throws an error if the account is not the owner of the offer with given id.
        @param offerId The id of the target offer.
        @param account The target account.
    */
    modifier isOfferOwner(uint256 offerId, address account) {
        require(idToOffer[offerId].offererAddress == account, Errors.NOT_ALLOWED);
        _;
    }

    /*
        @notice Accepts an offer made for a token. Credits are transferred to the buyer,
            while price deducted by royalties are send to the owner of the credits.
        @param offerId The id of the offer.
        @param amount The amount of credits .
    */
    function acceptOffer(uint256 offerId, uint256 amount) external {
        _acceptOffer(offerId, amount);
    }

    /*
        @notice Accepts an offer made for a token. Credits are transferred to the buyer,
            while price deducted by royalties are send to the owner of the credits.
            Purchase is repeated for each id and amount.
        @param ids The list of offer ids.
        @param amounts The list of amounts .
    */
    function acceptOfferBatch(uint256[] calldata ids, uint256[] calldata amounts) external {
        for (uint256 i = 0; i < ids.length; i++){
            _acceptOffer(ids[i], amounts[i]);
        }
    }

    /*
        @notice Closes an existing offer. The offered price is transferred back to the owner of the offer.
        @dev Can be called only by the owner of the offer.
        @param offerId The id of the offer.
    */
    function closeOffer(uint256 offerId)
        external
        isOfferOwner(offerId, msg.sender)
    {
        idToOffer[offerId].closed = true;
        IERC20(tokenAddress).transfer(msg.sender, idToOffer[offerId].price * idToOffer[offerId].quantity);

        emit OfferClosed(offerId, false);
    }

    /*
        @notice Opens a new offer. Proposed price is transferred from the offerer to the smart contract.
        @param tokenId The id of the tokens for which the offer is opened.
        @param price The price offered for the credits.
        @param quantity The amount of credits that will be purchased.
    */
    function makeOffer(uint256 tokenId, uint256 price, uint256 quantity) external {
        idToOffer[nOffers] = Offer(
            msg.sender,
            tokenId,
            quantity,
            price,
            false
        );
        IERC20(tokenAddress).transferFrom(msg.sender, bankContract, price * quantity);
        emit OfferCreated(tokenId, price, quantity, msg.sender);
    }

    /*
        @notice Updates the offer with given id. If the new total price is higher than the current one, the difference
            is transferred to the smart contract, otherwise the excess is transferred back to the caller.
        @dev The caller must be the owner of the offer.
        @param offerId The id of the target offer.
        @param price The new credit price.
        @param quantity The new quantity.
    */
    function updateOffer(uint256 offerId, uint256 price, uint256 quantity)
        external
        isOfferOwner(offerId, msg.sender)
    {
        if (idToOffer[offerId].price != price) {
            if (idToOffer[offerId].price > price) {
                IERC20(tokenAddress).transfer(
                    msg.sender,
                    (idToOffer[offerId].price - price) * idToOffer[offerId].quantity
                );
            } else {
                IERC20(tokenAddress).transferFrom(
                    msg.sender,
                    bankContract,
                    (price - idToOffer[offerId].price) * idToOffer[offerId].quantity
                );
            }
            idToOffer[offerId].price = price;
        }
        if (idToOffer[offerId].quantity != quantity) {
            idToOffer[offerId].quantity = quantity;
        }
        emit OfferUpdated(offerId, price, quantity);
    }

    /*
        @param offerId.
        @return The offer for the given id.
    */
    function getOffer(uint256 offerId) external view returns(Offer memory) {
        return idToOffer[offerId];
    }

    function _getCreditsContract() internal view virtual returns(address);

    function _acceptOffer(uint256 offerId, uint256 amount)
        offerActive(offerId)
        offerHasEnoughTokens(offerId, amount)
        private
    {
        uint256 total = idToOffer[offerId].price * amount;
        (address royaltiesReceiver, uint256 royalties) = IRoyalties(_getCreditsContract()).royaltyInfo(
            idToOffer[offerId].tokenId,
            total
        );

        IERC1155(_getCreditsContract()).safeTransferFrom(
            msg.sender,
            idToOffer[offerId].offererAddress,
            idToOffer[offerId].tokenId,
            amount,
            ""
        );
        idToOffer[offerId].quantity -= amount;

        IBank(bankContract).withdraw(msg.sender, total - royalties);
        IBank(bankContract).withdraw(royaltiesReceiver, royalties);

        if (idToOffer[offerId].quantity == 0) {
            idToOffer[offerId].closed = true;
            emit OfferClosed(offerId, true);
        }

        emit OfferUpdated(offerId, idToOffer[offerId].price, idToOffer[offerId].quantity);
        emit Purchase(
            idToOffer[offerId].tokenId,
            msg.sender,
            idToOffer[offerId].offererAddress,
            total,
            amount
        );
    }

    /*
        @notice Emitted when an offer is updated, closed, or accepted.
        @param offerId The id of the target offer.
        @param price The new price.
        @param quantity The new quantity.
    */
    event OfferUpdated(uint256 indexed offerId, uint256 price, uint256 quantity);

    /*
        @notice Emitted when a offer is closed.
        @param offerId The id of the offer.
        @param funded Set to true if the listing is closed after all the credits are bought, false otherwise.
    */
    event OfferClosed(uint256 indexed offerId, bool indexed funded);

    /*
        @notice Emitted when a new offer is created.
        @param creditId The id of the credits for which the offer is opened.
        @param price The offered price.
        @param quantity The required amount of credits.
        @param offerer The account that opened the offer.
    */
    event OfferCreated(uint256 indexed creditId, uint256 price, uint256 quantity, address offerer);
}
