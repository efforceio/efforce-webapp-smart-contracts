// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPurchase {

    /*
        @notice Emitted when a purchase is completed.
        @param creditId The id of the credits that have been sold.
        @param seller The account that sold the credits.
        @param buyer The account that bought the credits.
        @param price The total amount spent by the buyer.
        @param amount The amount of credits that have been sold.
        @param currency The ERC20 token spent by the buyer.
        @param royalties The amount of royalties received by the royalties receiver.
        @param royaltiesReceiver The account that will receive the royalties.
    */
    event PurchaseCompleted(
        uint256 indexed creditId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        uint256 amount,
        address currency,
        uint256 royalties,
        address royaltiesReceiver
    );

    /*
        @notice Emitted when a lending is completed.
        @param creditId The id of the credits that have been sold.
        @param owner The account that owns the credits.
        @param user The account that will be the user of the credits.
        @param price The total amount spent by the user.
        @param amount The amount of credits that have been lent.
        @param currency The ERC20 token spent by the user.
        @param expire The expiration timestamp of the lending.
        @param royalties The amount of royalties received by the royalties receiver.
        @param royaltiesReceiver The account that will receive the royalties.
    */
    event LendingCompleted(
        uint256 indexed creditId,
        address indexed owner,
        address indexed user,
        uint256 price,
        uint256 amount,
        address currency,
        uint256 expire,
        uint256 royalties,
        address royaltiesReceiver
    );

}
