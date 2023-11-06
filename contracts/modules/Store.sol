// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./Vintages.sol";
import "./ERC1155.sol";
import "../helpers/IERC20.sol";

abstract contract Store is Vintages, ERC1155 {

    mapping(uint256 => mapping(address => uint256)) private vintageIdToAmountPerBuyer;

    /*
        @notice Throws an error if the user has not pending credits for the given vintage.
        @param vintageId The id of the target vintage.
        @param account The target user.
    */
    modifier hasPendingCredits(uint256 vintageId, address account) {
        require(vintageIdToAmountPerBuyer[vintageId][account] > 0);
        _;
    }

    /*
        @notice If a funding vintage is open for project with given ID and credits are still available, users can buy
            the given amount of credits for a fixed price.
        @dev Funds sent by users cannot be withdrawn by the contract owner or admins until the vintage is open.
        @dev Only approved accounts can invoke this function.
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
        isVintageState(projectToActiveVintage[projectId], 0)
    {
        uint256 vintageId = projectToActiveVintage[projectId];
        uint256 totalPrice = vintageIdToDetails[vintageId].price * amount;

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), totalPrice);

        vintageIdToAmountPerBuyer[vintageId][msg.sender] += amount;
        vintageIdToDetails[vintageId].availableCredits -= amount;
        blockedERC20 += totalPrice;

        if (vintageIdToDetails[vintageId].availableCredits == 0) {
            vintageIdToDetails[vintageId].state = 1;
            emit VintageAction(vintageId, 1);
            _unlockFundsRaisedByVintage(vintageId);
        }

        emit FundsLockedUpdated(blockedERC20);
        emit CreditsPurchased(vintageId, amount, msg.sender);
    }

    /*
        @notice After a vintage is closed, if users have bought some credits, they can redeem them using this function.
        @param vintageId The id of the vintage.
    */
    function redeemCredits(uint256 vintageId)
        external
        isVintageState(vintageId, 1)
        hasPendingCredits(vintageId, msg.sender)
    {
        balances[vintageId][msg.sender] = vintageIdToAmountPerBuyer[vintageId][msg.sender];

        emit TransferSingle(
            msg.sender,
            address(0),
            msg.sender,
            vintageId,
            vintageIdToAmountPerBuyer[vintageId][msg.sender]
        );

        vintageIdToAmountPerBuyer[vintageId][msg.sender] = 0;
        emit RefundOrRedeem(msg.sender, vintageId, 1);
    }

    /*
        @notice After a vintage is canceled, if users have bought some credits, they can get the refund using
            this function.
        @param vintageId The id of the vintage.
    */
    function refundCredits(uint256 vintageId)
        external
        isVintageState(vintageId, 2)
        hasPendingCredits(vintageId, msg.sender)
    {
        uint256 nCredits = vintageIdToAmountPerBuyer[vintageId][msg.sender];
        uint256 totalPrice = vintageIdToDetails[vintageId].price * nCredits;
        IERC20(tokenAddress).transfer(msg.sender, totalPrice);
        blockedERC20 -= totalPrice;

        vintageIdToAmountPerBuyer[vintageId][msg.sender] = 0;

        emit FundsLockedUpdated(blockedERC20);
        emit RefundOrRedeem(msg.sender, vintageId, 2);
    }

    /*
        @param vintageId The id of the vintage.
        @param account The target account.
        @return The pending credits bought by the account for the given vintage.
    */
    function getPendingCredits(uint256 vintageId, address account)
        external
        view
        returns(uint256)
    {
        return vintageIdToAmountPerBuyer[vintageId][account];
    }

    /*
        @notice Emitted when a refund or credits redeem is completed.
        @param account The target account.
        @param vintageId The id of the vintage.
        @param action Set to 1 for redeem, 2 for refund.
    */
    event RefundOrRedeem(address indexed account, uint256 indexed vintageId, uint8 indexed action);

    /*
        @notice Emitted when the account buys some credits.
        @param id The credits ID.
        @param amount The amount of credits purchased.
        @param account The buyer.
    */
    event CreditsPurchased(uint256 indexed id, uint256 amount, address indexed account);
}
