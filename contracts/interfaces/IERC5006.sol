// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC5006 {

    struct UserRecord {
        uint256 tokenId;
        address owner;
        uint256 amount;
        address user;
        uint256 expiry;
    }

    /*
        @notice Gives permission to user to use amount of tokenId (id of credits) token owned by owner until expiry.
        @param owner The owner of the nfts.
        @param user The address that will be the user for the given amount.
        @param amount The amount of nfts that will be assigned to user.
        @param expiry The expiration timestamp.
        @return The id of the user record.
    */
    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint256 amount,
        uint256 expiry
    ) external returns(uint256);

    /*
        @notice Atomically delete record of recordId by the caller.
        @dev Only of owners of the recordId can delete the record.
        @param recordId The id of the record to be deleted.
    */
    function deleteUserRecord(uint256 recordId) external;

    /*
        @notice Returns the usable amount of tokenId tokens by account.
        @param account The target account.
        @param tokenId The target token id.
        @return The amount of tokens that the target account is user of.
    */
    function usableBalanceOf(address account, uint256 tokenId) external view returns(uint256);

    /*
        @notice Returns the amount of frozen tokens of token type id by account.
        @param account The target account.
        @param tokenId The target token id.
        @return The amount of tokens that are blocked for the target account with target token id.
    */
    function frozenBalanceOf(address account, uint256 tokenId) external view returns(uint256);

    /*
        @notice Returns the UserRecord of recordId.
        @param recordId The given record id.
        @return The details of the record with given id.
    */
    function userRecordOf(uint256 recordId) external view returns(UserRecord memory);

    /*
        @notice Emitted when permission for user to use amount of tokenId token owned by owner until expiry are given.
        @param recordId The id of the newly created record.
        @param tokenId The target token id for which the record is created.
        @param amount The amount of tokens that are lent.
        @param owner The owner of the tokens.
        @param user The address that is now user for the given tokens.
        @param expiry The expirity timestamp.
    */
    event CreateUserRecord(
        uint256 recordId,
        uint256 tokenId,
        uint256 amount,
        address indexed owner,
        address indexed user,
        uint256 expiry
    );

    /*
        @notice Emitted when record of recordId is deleted.
        @param recordId The id of the record which is deleted.
    */
    event DeleteUserRecord(uint256 recordId);
}
