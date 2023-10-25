// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./Projects.sol";
import "../libraries/Errors.sol";
import "../helpers/IERC20.sol";
import "./Bank.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract Fundings is Projects, Bank {

    struct Phase {
        uint256 totalCredits;
        uint256 availableCredits;
        uint256 price;
        bool open;
        uint256 openedTimestamp;
        uint256 tokenId;
    }

    uint256 private nPhases;
    mapping(uint256 => Phase) private projectIdToPhase;
    mapping(uint256 => mapping(address => uint256)) private phaseIdToAmountPerBuyer;
    mapping(uint256 => EnumerableSet.AddressSet) private phaseIdToBuyers;
    mapping(address => uint256) private blockedAmountForToken;

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

    /*
        @notice Opens a funding phase for project with given ID, allowing users to buy up to the given number
            of credits for fixed price.
        @dev Can be invoked only by the contract owner or admins.
        @dev New phases cannot be opened if there is already an open phase for the same project id.
        @param projectId The project id for which a new funding phase will be opened.
        @param credits The number of credits that will be minted if the funding phase is successful.
        @param price The price of each credit.
    */
    function openPhase(
        uint256 projectId,
        uint256 credits,
        uint256 price
    )
        external
        adminOrOwner(msg.sender)
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
            lastCreditsId
        );

        emit PhaseAction(nPhases, true, credits, price, false);
    }

    /*
        @notice If a funding phase is open for project with given ID and credits are still available, users can buy
            the given amount of credits for a fixed price - funds sent by users cannot be withdrawn by the contract
            manager until the phase is open - only approved accounts can invoke this function.
        @param projectId The project id for which credits will be purchased.
        @param amount The amount of credits that will be purchased.
    */
    function buyCredits(
        uint256 projectId,
        uint256 amount
    )
        external
        availableCredits(projectId, amount)
        accountEnabled(msg.sender)
        phaseOpen(projectId)
    {
        uint256 phaseId = projectIdToPhase[projectId].tokenId;
        uint256 price = projectIdToPhase[projectId].price * amount;

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), price);

        phaseIdToAmountPerBuyer[phaseId][msg.sender] += amount;
        EnumerableSet.add(phaseIdToBuyers[phaseId], msg.sender);
        projectIdToPhase[projectId].availableCredits -= amount;
        blockedAmountForToken[tokenAddress] += price;

        emit CreditsPurchased(phaseId, amount, msg.sender);
    }

    /*
        @notice If the funding phase is successful, refund has to be set to false and users will receive previously
            purchased credits (phase closed successfully), otherwise, the refund has to be set to false and users
            will receive back the ERC20 tokens they have spent (phase closed unsuccessfully).
        @dev Can be invoked only by the contract owner or managers.
        @param projectId The project id for which the funding phase will be closed.
        @param refund If set to true, the funding phase is unsuccessful and received tokens will be refund,
            otherwise credits are distributed and funds unblocked.
    */
    function closePhase(
        uint256 projectId,
        bool refund
    )
        external
        adminOrOwner(msg.sender)
        phaseOpen(projectId)
    {
        uint256 phaseId = projectIdToPhase[projectId].tokenId;
        uint256 pricePerCredit = projectIdToPhase[projectId].price;

        for (uint256 i = 0; i < EnumerableSet.length(phaseIdToBuyers[phaseId]); i++) {
            uint256 amount = phaseIdToAmountPerBuyer[phaseId][EnumerableSet.at(phaseIdToBuyers[phaseId], i)];
            address account = EnumerableSet.at(phaseIdToBuyers[phaseId], i);
            uint256 price = amount * pricePerCredit;

            if (refund) {
                IERC20(tokenAddress).transfer(account, price);
            } else {
                balances[phaseId][account] = amount;
            }

            blockedAmountForToken[tokenAddress] -= price;
        }

        projectIdToPhase[projectId].open = false;

        emit PhaseAction(
            phaseId,
            false,
            projectIdToPhase[projectId].totalCredits,
            pricePerCredit,
            refund
        );
    }

    /*
        @notice Returns the details of the phase of project with given credits ID.
        @param projectId The id of the target project.
        @return The details of the funding phase for target project.
    */
    function getPhaseForProject(
        uint256 projectId
    )
        external
        view
        returns(Phase memory)
    {
        return projectIdToPhase[projectId];
    }


    function _blockedAmount()
        internal
        override
        view
        returns(uint256)
    {
        return blockedAmountForToken[tokenAddress];
    }

    /*
        @notice Emitted when a funding phase is opened or closed.
        @param id The id of the funding phase (credits id).
        @param opened Set to false if the phase is closed, true otherwise.
        @param credits The number of credits.
        @param price The price of credits.
        @param timestamp The opening timestamp.
        @param refund Set to true if the funding phase was unsuccessful, false otherwise.
    */
    event PhaseAction(
        uint256 indexed id,
        bool indexed opened,
        uint256 credits,
        uint256 price,
        bool refund
    );

    /*
        @notice Emitted when the account buys some credits.
        @param id The credits ID.
        @param amount The amount of credits purchased.
        @param account The buyer.
    */
    event CreditsPurchased(uint256 indexed id, uint256 amount, address indexed account);

}
