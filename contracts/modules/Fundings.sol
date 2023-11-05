// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./Projects.sol";
import "../libraries/Errors.sol";
import "../helpers/IERC20.sol";
import "./Bank.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract Fundings is Projects, Bank {

    struct Vintage {
        uint256 totalCredits;
        uint256 availableCredits;
        uint256 price;
        bool open;
        uint256 openedTimestamp;
        uint256 tokenId;
    }

    uint256 public numberOfVintages;
    mapping(uint256 => Vintage) private projectToVintage;
    mapping(uint256 => mapping(address => uint256)) private vintageIdToAmountPerBuyer;
    mapping(uint256 => EnumerableSet.AddressSet) private vintageIdToBuyers;
    mapping(address => uint256) private blockedAmountForToken;

    modifier noPreviousVintage(uint256 projectId) {
        require(!projectToVintage[projectId].open, Errors.VINTAGE_ALREADY_OPEN);
        _;
    }

    modifier vintageOpen(uint256 projectId) {
        require(projectToVintage[projectId].open, Errors.VINTAGE_NOT_OPEN);
        _;
    }

    modifier availableCredits(uint256 projectId, uint256 credits) {
        require(projectToVintage[projectId].availableCredits >= credits, Errors.CREDITS_NOT_AVAILABLE);
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
        noPreviousVintage(projectId)
    {
        numberOfVintages++;
        lastCreditsId++;

        uint256 timestamp = block.timestamp;

        projectToVintage[projectId] = Vintage(
            credits,
            credits,
            price,
            true,
            timestamp,
            lastCreditsId
        );

        emit VintageAction(numberOfVintages, true, credits, price, false);
    }

    /*
        @notice If a funding vintage is open for project with given ID and credits are still available, users can buy
            the given amount of credits for a fixed price - funds sent by users cannot be withdrawn by the contract
            manager until the vintage is open - only approved accounts can invoke this function.
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
        vintageOpen(projectId)
    {
        uint256 vintageId = projectToVintage[projectId].tokenId;
        uint256 price = projectToVintage[projectId].price * amount;

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), price);

        vintageIdToAmountPerBuyer[vintageId][msg.sender] += amount;
        EnumerableSet.add(vintageIdToBuyers[vintageId], msg.sender);
        projectToVintage[projectId].availableCredits -= amount;
        blockedAmountForToken[tokenAddress] += price;

        emit CreditsPurchased(vintageId, amount, msg.sender);
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
    function closeVintage(
        uint256 projectId,
        bool refund
    )
        external
        adminOrOwner(msg.sender)
        vintageOpen(projectId)
    {
        uint256 vintageId = projectToVintage[projectId].tokenId;
        uint256 pricePerCredit = projectToVintage[projectId].price;

        for (uint256 i = 0; i < EnumerableSet.length(vintageIdToBuyers[vintageId]); i++) {
            uint256 amount = vintageIdToAmountPerBuyer[vintageId][EnumerableSet.at(vintageIdToBuyers[vintageId], i)];
            address account = EnumerableSet.at(vintageIdToBuyers[vintageId], i);
            uint256 price = amount * pricePerCredit;

            if (refund) {
                IERC20(tokenAddress).transfer(account, price);
            } else {
                balances[vintageId][account] = amount;
            }

            blockedAmountForToken[tokenAddress] -= price;
        }

        projectToVintage[projectId].open = false;

        emit VintageAction(
            vintageId,
            false,
            projectToVintage[projectId].totalCredits,
            pricePerCredit,
            refund
        );
    }

    /*
        @notice Returns the details of the vintage of project with given credits ID.
        @param projectId The id of the target project.
        @return The details of the funding vintage for target project.
    */
    function getVintageForProject(
        uint256 projectId
    )
        external
        view
        returns(Vintage memory)
    {
        return projectToVintage[projectId];
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
        @notice Emitted when a funding vintage is opened or closed.
        @param id The id of the funding vintage (credits id).
        @param opened Set to false if the vintage is closed, true otherwise.
        @param credits The number of credits.
        @param price The price of credits.
        @param timestamp The opening timestamp.
        @param refund Set to true if the funding vintage was unsuccessful, false otherwise.
    */
    event VintageAction(
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
