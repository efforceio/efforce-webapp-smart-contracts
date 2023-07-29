// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IProjects.sol";
import "./ERC1155.sol";
import "../libraries/Errors.sol";

abstract contract Projects is IProjects, ERC1155 {

    uint256 private nProjects;
    mapping(uint256 => uint256) private creditIdToProjectId;

    constructor() {
        nProjects = 0;
    }

    modifier projectExists(uint256 projectId) {
        require(projectId > 0 && projectId <= nProjects, Errors.NOT_EXISTS);
        _;
    }

    function createProject()
        external
        override
        managerOrOwner(msg.sender)
        returns(uint256)
    {
        nProjects++;
        emit ProjectCreation(nProjects);

        return nProjects;
    }

    function newCreditsForProject(
        uint256 projectId,
        uint256 amount,
        address receiver
    )
        external
        managerOrOwner(msg.sender)
        projectExists(projectId)
        accountEnabled(receiver)
        override
        returns(uint256)
    {
        lastCreditsId++;
        balances[lastCreditsId][receiver] = amount;
        creditIdToProjectId[lastCreditsId] = projectId;

        emit NewCreditsReleased(lastCreditsId, projectId, amount, receiver);

        return lastCreditsId;
    }

    function projectIdForCredit(
        uint256 creditId
    )
        external
        override
        view
        returns(uint256)
    {
        uint256 projectId = creditIdToProjectId[creditId];
        require(projectId > 0, Errors.NOT_EXISTS);
        return projectId;
    }

}
