// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IFundings.sol";
import "./Projects.sol";
import "../libraries/Errors.sol";
import "../helpers/IERC20.sol";
import "./Bank.sol";

abstract contract Fundings is IFundings, Projects, Bank {

    uint256 private nPhases;
    mapping(uint256 => Phase) private projectIdToPhase;
    mapping(uint256 => mapping(address => uint256)) private phaseIdToAmountPerBuyer;
    mapping(uint256 => address[]) private phaseIdToBuyers;
    mapping(address => uint256) private blockedAmountForToken;

    constructor() {
        nPhases = 0;
    }

    modifier noPreviousPhase(uint256 projectId) {
        require(!projectIdToPhase[projectId].open, Errors.PHASE_ALREADY_OPEN);
        _;
    }

    modifier phaseOpen(uint256 projectId) {
        require(projectIdToPhase[projectId].open, Errors.PHASE_NOT_OPEN);
        _;
    }

    modifier availableCredits(uint256 projectId, uint256 credits) {
        require(projectIdToPhase[projectId].availableCredits >= credits, Errors.CREDITS_NOT_AVAILABLE);
        _;
    }

    function openPhase(
        uint256 projectId,
        uint256 credits,
        uint256 price,
        address tokenAddress
    )
        external
        override
        managerOrOwner(msg.sender)
        noPreviousPhase(projectId)
    {
        nPhases++;
        lastCreditsId++;

        uint256 timestamp = block.timestamp;

        projectIdToPhase[projectId] = Phase(
            credits,
            credits,
            price,
            true,
            timestamp,
            tokenAddress,
            lastCreditsId
        );

        emit PhaseAction(nPhases, true, credits, price, timestamp, tokenAddress, false);
    }

    function buyCredits(
        uint256 projectId,
        uint256 amount
    )
        external
        override
        availableCredits(projectId, amount)
        accountEnabled(msg.sender)
        phaseOpen(projectId)
    {
        uint256 phaseId = projectIdToPhase[projectId].tokenId;
        uint256 price = projectIdToPhase[projectId].price * amount;
        address currency = projectIdToPhase[projectId].currencyAddress;

        IERC20(currency).transferFrom(msg.sender, address(this), price);
        phaseIdToAmountPerBuyer[phaseId][msg.sender] += amount;
        phaseIdToBuyers[phaseId].push(msg.sender);
        projectIdToPhase[projectId].availableCredits -= amount;
        blockedAmountForToken[currency] += price;

        emit CreditsPurchased(phaseId, amount, msg.sender);
    }

    function closePhase(
        uint256 projectId,
        bool refund
    )
        external
        override
        managerOrOwner(msg.sender)
        phaseOpen(projectId)
    {
        uint256 phaseId = projectIdToPhase[projectId].tokenId;
        address currency = projectIdToPhase[projectId].currencyAddress;
        uint256 pricePerCredit = projectIdToPhase[projectId].price;

        for (uint256 i = 0; i < phaseIdToBuyers[phaseId].length; i++) {
            uint256 amount = phaseIdToAmountPerBuyer[phaseId][phaseIdToBuyers[phaseId][i]];
            address account = phaseIdToBuyers[phaseId][i];
            uint256 price = amount * pricePerCredit;

            if (refund) {
                IERC20(currency).transfer(account, price);
            } else {
                balances[phaseId][account] = amount;
                blockedAmountForToken[currency] -= price;
            }
        }

        projectIdToPhase[projectId].open = false;

        emit PhaseAction(
            phaseId,
            false,
            projectIdToPhase[projectId].totalCredits,
            pricePerCredit,
            projectIdToPhase[projectId].openedTimestamp,
            currency,
            refund
        );
    }

    function getPhaseForProject(
        uint256 projectId
    )
        external
        view
        override
        returns(Phase memory)
    {
        return projectIdToPhase[projectId];
    }


    function _blockedAmountForToken(
        address token
    )
        internal
        virtual
        override
        returns(uint256)
    {
        return blockedAmountForToken[token];
    }

}
