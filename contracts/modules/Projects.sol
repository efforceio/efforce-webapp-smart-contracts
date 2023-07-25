// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IProjects.sol";
import "./ERC5006.sol";
import "../libraries/Errors.sol";

contract Projects is IProjects, ERC5006 {

    uint256 private nProjects;
    mapping(uint256 => uint256) private creditIdToProjectId;

    constructor(
        address owner,
        string memory metadataUri
    ) ERC5006(owner, metadataUri) {
        nProjects = 0;
    }

    modifier projectExists(uint256 projectId) {
        require(projectId > 0 && projectId <= nProjects, Errors.PROJECT_NOT_EXISTS);
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
        returns(uint256)
    {
        return creditIdToProjectId[creditId];
    }

}
