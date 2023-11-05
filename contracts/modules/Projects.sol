// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../libraries/Errors.sol";
import "./RolesModifier.sol";

abstract contract Projects is RolesModifier {

    uint256 public numberOfProjects;

    /*
        @notice Throws an error if the project with given id does not exist.
        @param projectId The target project id.
    */
    modifier projectExists(uint256 projectId) {
        require(projectId < numberOfProjects, Errors.NOT_EXISTS);
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
        @note Emitted when a new project is created.
        @param projectId The id of the new created project.
    */
    event ProjectCreation(uint256 projectId);

}
