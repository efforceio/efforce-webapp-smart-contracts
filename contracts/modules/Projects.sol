// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./ERC1155.sol";
import "../libraries/Errors.sol";

abstract contract Projects is ERC1155 {

    uint256 public numberOfProjects;
    mapping(uint256 => uint256) private creditIdToProjectId;

    /*
        @notice Throws an error if the project with given id does not exist.
        @param projectId The target project id.
    */
    modifier projectExists(uint256 projectId) {
        require(projectId > 0 && projectId <= numberOfProjects, Errors.NOT_EXISTS);
        _;
    }

    /*
        @note Creates a new project and returns its id.
        @dev Can be invoked only by contract owner and owners.
        @return The id of the new project.
    */
    function createProject()
        external
        adminOrOwner(msg.sender)
    {
        emit ProjectCreation(numberOfProjects);
        numberOfProjects++;
    }

    /*
        @note Creates new credits for the given project and returns the id of the new issued tokens.
        @dev Can be invoked only by contract owner and owners.
        @param projectId The target project id.
        @param amount The amount of credits that will be created for target project id.
        @param receiver The address that will receive the new generated credits.
        @return The id of the new credits.
    */
    function newCreditsForProject(
        uint256 projectId,
        uint256 amount,
        address receiver
    )
        external
        adminOrOwner(msg.sender)
        projectExists(projectId)
        accountEnabled(receiver)
        returns(uint256)
    {
        lastCreditsId++;
        balances[lastCreditsId][receiver] = amount;
        creditIdToProjectId[lastCreditsId] = projectId;

        emit NewCreditsReleased(lastCreditsId, projectId, amount, receiver);

        return lastCreditsId;
    }

    /*
        @note Returns the project id for the given credit id.
        @param creditId The target credits id.
        @return The id of the project linked to target credit id.
    */
    function projectIdForCredit(
        uint256 creditId
    )
        external
        view
        returns(uint256)
    {
        uint256 projectId = creditIdToProjectId[creditId];
        require(projectId > 0, Errors.NOT_EXISTS);
        return projectId;
    }

    /*
        @note Emitted when a new project is created.
        @param projectId The id of the new created project.
    */
    event ProjectCreation(uint256 projectId);

    /*
        @note Emitted when new credits are released.
        @param creditsId The id of the newly created credits.
        @param projectId The target project id.
        @param amount The amount of credits that will be created for target project id.
        @param receiver The address that will receive the new generated credits.
    */
    event NewCreditsReleased(uint256 creditsId, uint256 indexed projectId, uint256 amount, address indexed receiver);

}
