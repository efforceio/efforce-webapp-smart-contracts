// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155 {
    /*
        @notice Transfers _value amount of an _id from the _from address to the _to address specified
            (with safety call).
        @dev The transaction must be reverted if the receiver is not allowed.
        @param _from The account form which the tokens will be transferred.
        @param _to The account which will receive the tokens.
        @param _id The id of the tokens that will be transferred.
        @param _value The amount of token that will be transferred.
        @param data Information that will be passed to the receiver if it is a smart contract.
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata data
    ) external;

    /*
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @param _operator The target address.
        @param _approved Set to true if the target address will be an operator, false otherwise.
    */
    function setApprovalForAll(address _operator, bool _approved) external;
}
