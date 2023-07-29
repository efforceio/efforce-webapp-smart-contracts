// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IProjects {

    /*
        @note Creates a new project and returns its id.
        @dev Can be invoked only by contract owner and managers.
        @return The id of the new project.
    */
    function createProject() external returns(uint256);

    /*
        @note Creates new credits for the given project and returns the id of the new issued tokens.
        @dev Can be invoked only by contract owner and managers.
        @param projectId The target project id.
        @param amount The amount of credits that will be created for target project id.
        @param receiver The address that will receive the new generated credits.
        @return The id of the new credits.
    */
    function newCreditsForProject(uint256 projectId, uint256 amount, address receiver) external returns(uint256);

    /*
        @note Returns the project id for the given credit id.
        @param creditId The target credits id.
        @return The id of the project linked to target credit id.
    */
    function projectIdForCredit(uint256 creditId) external view returns(uint256);

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
