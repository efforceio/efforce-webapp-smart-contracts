// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./helpers/IERC20.sol";
import "./modules/BankWrapper.sol";
import "./interfaces/ICredits.sol";
import "./interfaces/IERC1155.sol";
import "./modules/RolesModifier.sol";
import "./interfaces/IAccount.sol";

contract Store is BankWrapper, RolesModifier {

    address public immutable creditsContract;

    constructor(address _credits, address _bankAddress, address _rolesAddress) {
        rolesAddress = _rolesAddress;
        tokenAddress = IBank(_bankAddress).tokenAddress();
        bankContract = _bankAddress;
        creditsContract = _credits;
    }

    /*
        @notice Raises an error if the input account is not enabled for tradings.
        @param account The target account.
    */
    modifier accountEnabled(address account) {
        require(IAccount(creditsContract).isAccountEnabled(account), Errors.IS_NOT_ENABLED);
        _;
    }

    /*
        @notice Throw an error if users has not credits to redeem or refund.
        @param projectId The id of the vintage.
        @param state The query state.
    */
    modifier availableCredits(uint vintageId, uint credits) {
        require(
            ICredits(creditsContract).getVintage(vintageId).availableCredits >= credits,
            Errors.CREDITS_NOT_AVAILABLE
        );
        _;
    }

    /*
        @notice Throw an error if the state of the vintage is different from the one provided.
        @param vintageId The id of the vintage.
        @param state The query state.
    */
    modifier isVintageState(uint vintageId, uint state) {
        require( ICredits(creditsContract).getVintage(vintageId).state == state, Errors.INCORRECT_VINTAGE_STATE);
        _;
    }

    /*
        @notice If the funding vintage is open and credits are still available, users can buy the given amount
            of credits for a fixed price.
        @dev Funds sent by users cannot be withdrawn by the contract owner or admins until the vintage is open.
        @dev Only approved accounts can invoke this function.
        @param vintageId The vintage id for which credits will be purchased.
        @param amount The amount of credits that will be purchased.
    */
    function buyCredits(uint vintageId, uint256 amount)
        external
        availableCredits(vintageId, amount)
        accountEnabled(msg.sender)
        isVintageState(vintageId, 0)
    {
        _buyCredits(vintageId, amount, msg.sender, true);
    }

    /*
        @notice Allows to buy credits using external payments modes.
        @dev Cab be called only by contract owner or admins.
        @dev The receiver must be an allowed account.
        @param vintageId The id of the vintage.
        @param amount The amount of credits that are bought.
        @param receiver The address that will receive the credits.
    */
    function buyCreditsFor(uint256 vintageId, uint256 amount, address receiver)
        external
        availableCredits(vintageId, amount)
        accountEnabled(receiver)
        adminOrOwner(msg.sender)
        isVintageState(vintageId, 0)
    {
        _buyCredits(vintageId, amount, receiver, false);
    }

    /*
        @notice After a vintage is canceled, if users have bought some credits, they can get the refund using
            this function.
        @param vintageId The id of the vintage.
    */
    function refundCredits(uint256 vintageId)
        external
        isVintageState(vintageId, 2)
    {
        uint256 nCredits = IERC1155(creditsContract).balanceOf(msg.sender, vintageId);
        uint256 totalPrice = ICredits(creditsContract).getVintage(vintageId).price * nCredits;
        IBank(bankContract).withdraw(msg.sender, totalPrice);
        ICredits(creditsContract).burn(msg.sender, vintageId, nCredits, "");
        uint projectId = ICredits(creditsContract).getVintage(vintageId).projectId;

        emit RefundOrRedeem(msg.sender, vintageId, projectId);
    }


    function _buyCredits(uint256 vintageId, uint256 amount, address receiver, bool crypto)
        internal
    {
        ICredits.Vintage memory v = ICredits(creditsContract).getVintage(vintageId);
        ICredits(creditsContract).updateVintageAvailability(
            vintageId,
            v.availableCredits - amount
        );
        ICredits(creditsContract).safeMint(receiver, vintageId, amount, "");

        if (crypto) {
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                bankContract,
                amount * v.price
            );
        }

        emit CreditsPurchased(vintageId, amount, v.price, receiver, receiver == msg.sender, v.projectId);
    }

    /*
        @notice Emitted when a refund or credits redeem is completed.
        @param account The target account.
        @param vintageId The id of the vintage.
        @param projectId The id of the credits project.
    */
    event RefundOrRedeem(address account, uint256 indexed vintageId, uint256 indexed projectId);

    /*
        @notice Emitted when the account buys some credits.
        @param id The credits ID.
        @param amount The amount of credits purchased.
        @param account The buyer.
        @param crypto Is set to true if the sender is making the payment, false otherwise.
        @param projectId The id of the credits project.
    */
    event CreditsPurchased(
        uint256 indexed id,
        uint256 amount,
        uint256 pricePerCredit,
        address indexed account,
        bool crypto,
        uint256 indexed projectId
    );
}
