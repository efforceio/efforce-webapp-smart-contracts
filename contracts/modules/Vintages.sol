// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./Projects.sol";
import "../libraries/Errors.sol";
import "../Roles.sol";
import "./BankWrapper.sol";

abstract contract Vintages is Projects, BankWrapper {

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
        @param projectId The project id for which a new funding vintage will be opened.
        @param credits The number of credits that will be minted if the funding vintage is successful.
        @param price The price of each credit.
    */
    function openVintage(uint256 projectId, uint256 credits, uint256 price)
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
        @notice Closes or cancels an open vintage.
        @dev Can be invoked only by the contract owner or managers.
        @dev Can be invoked only if the vintage is open.
        @param vintageId The id of the vintage that will be updated.
        @param newState The new state can be 1 (closed) or 2 (canceled).
    */
    function updateVintageState(uint256 vintageId, uint8 newState)
        external
        adminOrOwner(msg.sender)
        isVintageState(vintageId, 0)
        isValidState(newState)
    {
        vintageIdToDetails[vintageId].state = newState;
        emit VintageAction(vintageId, newState);
    }

    /*
        @param vintageId The id of the target vintage.
        @return The details of the vintage of given id.
    */
    function getVintage(uint256 vintageId)
        external
        view
        isValidVintageId(vintageId)
        returns(Vintage memory)
    {
        return vintageIdToDetails[vintageId];
    }

    /*
        @notice Emitted when a funding vintage is opened or closed.
        @param id The id of the funding vintage (credits id).
        @param credits The number of credits.
        @param price The price of credits.
        @param projectId the projectId for the new issued credits.
    */
    event VintageOpened(uint256 indexed id, uint256 credits, uint256 price, uint256 indexed projectId);

    /*
        @notice Emitted when the state of a vintage is updated.
        @param vintageId The target vintage id.
        @param action Set to 1 if the vintage is closed, 2 if canceled.
    */
    event VintageAction(uint256 indexed vintageId, uint8 indexed action);

    /*
        @notice Emitted when the number of total credits of a vintage is updated.
            Can be invoked by burn or mint functions.
        @param vintageId The id of the target vintage.
        @param newCredits The new number of total credits.
    */
    event VintageUpdatedCredits(uint256 indexed vintageId, uint256 newCredits);
}
