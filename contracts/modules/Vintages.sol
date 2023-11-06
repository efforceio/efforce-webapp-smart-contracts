// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./Projects.sol";
import "../libraries/Errors.sol";
import "../Roles.sol";
import "./Bank.sol";

abstract contract Vintages is Projects, Bank {

    struct Vintage {
        uint256 totalCredits;
        uint256 availableCredits;
        uint256 price;
        uint8 state;
        uint256 projectId;
    }

    uint256 private numberOfVintages;

    mapping(uint256 => Vintage) internal vintageIdToDetails;

    /*
        @notice Throw an error if the state of the vintage is different from the one provided.
        @param vintageId The id of the vintage.
        @param state The query state.
    */
    modifier isVintageState(uint256 vintageId, uint8 state) {
        require(vintageIdToDetails[vintageId].state == state, Errors.INCORRECT_VINTAGE_STATE);
        _;
    }

    /*
        @notice Throw an error if users has not credits to redeem or refund.
        @param projectId The id of the vintage.
        @param state The query state.
    */
    modifier availableCredits(uint256 vintageId, uint256 credits) {
        require(
            vintageIdToDetails[vintageId].availableCredits >= credits,
            Errors.CREDITS_NOT_AVAILABLE
        );
        _;
    }

    /*
        @notice Throws an error if the state is not valid.
        @param state The state that has to be checked.
    */
    modifier isValidState(uint256 state) {
        require(state < 3, Errors.NOT_VALID_STATE);
        _;
    }

    /*
        @notice Throws an error if the vintage id not exists.
        @param vintageId The target vintage id.
    */
    modifier isValidVintageId(uint256 vintageId) {
        require(vintageId < numberOfVintages, Errors.CREDITS_NOT_AVAILABLE);
        _;
    }

    /*
        @notice Opens a funding vintage for project with given ID, allowing users to buy up to the given number
            of credits for fixed price.
        @dev Can be invoked only by the contract owner or admins.
        @dev New vintages cannot be opened if there is already an open vintage for the same project id.
        @param projectId The project id for which a new funding vintage will be opened.
        @param credits The number of credits that will be minted if the funding vintage is successful.
        @param price The price of each credit.
    */
    function openVintage(
        uint256 projectId,
        uint256 credits,
        uint256 price
    )
        external
        adminOrOwner(msg.sender)
    {
        vintageIdToDetails[numberOfVintages] = Vintage(
            credits,
            credits,
            price,
            0,
            projectId
        );

        emit VintageOpened(numberOfVintages, credits, price, projectId);
        numberOfVintages++;
    }


    /*
        @notice If the funding vintage is successful, refund has to be set to false and users will receive previously
            purchased credits (vintage closed successfully), otherwise, the refund has to be set to false and users
            will receive back the ERC20 tokens they have spent (vintage closed unsuccessfully).
        @dev Can be invoked only by the contract owner or managers.
        @param projectId The project id for which the funding vintage will be closed.
        @param refund If set to true, the funding vintage is unsuccessful and received tokens will be refund,
            otherwise credits are distributed and funds unblocked.
    */
    function updateVintageState(uint256 vintageId, uint8 newState)
        external
        adminOrOwner(msg.sender)
        isVintageState(vintageId, 0)
        isValidState(newState)
    {
        vintageIdToDetails[vintageId].state = newState;

        if (newState == 1) {
            _unlockFundsRaisedByVintage(vintageId);
        }

        emit VintageAction(vintageId, newState);
    }

    /*
        @notice Returns the details of the vintage of project with given vintage id.
        @param vintageId The id of the target vintage.
        @return The details of the funding vintage for target project.
    */
    function getVintage(uint256 vintageId)
        external
        view
        returns(Vintage memory)
    {
        return vintageIdToDetails[vintageId];
    }

    function _unlockFundsRaisedByVintage(uint256 vintageId)
        internal
    {
        uint256 purchasedCredits = vintageIdToDetails[vintageId].totalCredits -
            vintageIdToDetails[vintageId].availableCredits;
        blockedERC20 -= purchasedCredits * vintageIdToDetails[vintageId].price;

        emit FundsLockedUpdated(blockedERC20);
    }

    /*
        @notice Emitted when a funding vintage is opened or closed.
        @param id The id of the funding vintage (credits id).
        @param credits The number of credits.
        @param price The price of credits.
        @param projectId the projectId for the new issued credits.
    */
    event VintageOpened(
        uint256 indexed id,
        uint256 credits,
        uint256 price,
        uint256 indexed projectId
    );

    /*
        @notice Emitted when the state of a vintage is updated.
        @param vintageId The target vintage id.
        @param action Set to 1 if the vintage is closed, 2 if canceled.
    */
    event VintageAction(uint256 indexed vintageId, uint8 indexed action);

    event VintageUpdatedCredits(uint256 indexed vintageId, uint256 newCredits);
}
