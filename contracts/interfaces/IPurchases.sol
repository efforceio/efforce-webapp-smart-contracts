// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IPurchases {

    /*
        @notice Emitted when a purchase is completed for given credits.
        @param creditId The id of the target credit.
        @param seller The account that sold the credits.
        @param buyer The account that bought the credits.
        @param price The price for the operation, payed by the buyer.
        @param amount The amount of credits sold with given id.
    */
    event Purchase(
        uint256 indexed creditId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        uint256 amount
    );

}
