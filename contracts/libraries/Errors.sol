// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Errors {

    // Roles
    string constant public NOT_ALLOWED = "000";

    // Bank
    string constant public BALANCE_NOT_AVAILABLE = "100";

    //Accounts
    string constant public IS_NOT_ENABLED = "200";
    string constant public IS_ZERO_ADDRESS = "201";

    //ERC1155
    string constant public NOT_OWNER_OR_OPERATOR = "300";
    string constant public UNKNOWN_VALUE_FROM_SAFE_TRANSFER = "301";
    string constant public NOT_MATCHING_LENGTHS = "302";
    string constant public INSUFFICIENT_BALANCE = "303";

    //ERC5006
    string constant public NOT_EXPIRED = "400";
}
