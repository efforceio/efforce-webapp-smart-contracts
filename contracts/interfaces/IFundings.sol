// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFundings {

    struct Phase {
        uint256 totalCredits;
        uint256 availableCredits;
        uint256 price;
        bool open;
        uint64 openedTimestamp;
        address currencyAddress;
        uint256 tokenId;
    }

    /*
        @notice Opens a funding phase for project with given ID, allowing users to buy up to the given number
            of credits for fixed price.
        @dev Can be invoked only by the contract owner or managers.
        @dev New phases cannot be opened if there is already an open phase for the same project id.
        @param projectId The project id for which a new funding phase will be opened.
        @param credits The number of credits that will be minted if the funding phase is successful.
        @param price The price of each credit.
        @param tokenAddress The ERC20 token used for payments.
    */
    function openPhase(uint256 projectId, uint256 credits, uint256 price, address tokenAddress) external;

    /*
        @notice If a funding phase is open for project with given ID and credits are still available, users can buy
            the given amount of credits for a fixed price - funds sent by users cannot be withdrawn by the contract
            manager until the phase is open - only approved accounts can invoke this function.
        @param projectId The project id for which credits will be purchased.
        @param amount The amount of credits that will be purchased.
    */
    function buyCredits(uint256 projectId, uint256 amount) external;

    /*
        @notice If the funding phase is successful, refund has to be set to false and users will receive previously
            purchased credits (phase closed successfully), otherwise, the refund has to be set to false and users
            will receive back the ERC20 tokens they have spent (phase closed unsuccessfully).
        @dev Can be invoked only by the contract owner or managers.
        @param projectId The project id for which the funding phase will be closed.
        @param refund If set to true, the funding phase is unsuccessful and received tokens will be refund,
            otherwise credits are distributed and funds unblocked.
    */
    function closePhase(uint256 projectId, bool refund) external;

    /*
        @notice Returns the details of the phase of project with given credits ID.
        @param projectId The id of the target project.
        @return The details of the funding phase for target project.
    */
    function getPhaseForProject(uint256 projectId) external view returns(Phase);

    /*
        @notice Emitted when a funding phase is opened or closed.
        @param id The id of the funding phase (credits id).
        @param opened Set to false if the phase is closed, true otherwise.
        @param credits The number of credits.
        @param price The price of credits.
        @param timestamp The opening timestamp.
        @param currencyAddress The token address.
        @param refund Set to true if the funding phase was unsuccessful, false otherwise.
    */
    event PhaseAction(
        uint256 indexed id,
        bool indexed opened,
        uint256 credits,
        uint256 price,
        uint64 timestamp,
        address currencyAddress,
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
