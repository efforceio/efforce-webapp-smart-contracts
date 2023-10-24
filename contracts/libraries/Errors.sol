// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

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

    //General
    string constant public NOT_EXISTS = "500";

    //Fundings
    string constant public PHASE_ALREADY_OPEN = "600";
    string constant public CREDITS_NOT_AVAILABLE = "601";
    string constant public PHASE_NOT_OPEN = "602";

    //Pools
    string constant public POOL_IS_OPEN = "700";
    string constant public STAKING_NOT_ALLOWED = "701";
    string constant public FUNDS_LOCKED = "702";
    string constant public NOT_ALLOCATED = "702";
}
