// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./ERC1155.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract ERC5006 is ERC1155 {

    struct UserRecord {
        uint256 tokenId;
        address owner;
        uint256 amount;
        address user;
        uint256 expiry;
    }

    mapping(uint256 => UserRecord) private records;
    mapping(address => mapping(uint256 => uint256)) private frozen;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) private usersToRecordsSet;
    uint256 private currentRecord;

    /*
        @notice Throws an error if the record is not expired.
        @param recordId The id of the target record.
    */
    modifier expiredRecord(uint256 recordId) {
        require(records[recordId].expiry < block.timestamp, Errors.NOT_EXPIRED);
        _;
    }


    /*
        @notice Gives permission to user to use amount of tokenId (id of credits) token owned by owner until expiry.
        @param owner The owner of the nfts.
        @param user The address that will be the user for the given amount.
        @param tokenId The token (vintage) id.
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
    )
        external
        ownerOrOperator(owner)
        accountEnabled(user)
        hasValue(owner, amount, tokenId)
        returns(uint256)
    {
        records[currentRecord] = UserRecord(
            tokenId,
            owner,
            amount,
            user,
            expiry
        );
        frozen[owner][tokenId] += amount;
        EnumerableSet.add(usersToRecordsSet[user][tokenId], currentRecord);

        emit CreateUserRecord(currentRecord, tokenId, amount, owner, user, expiry);

        unchecked {
            currentRecord++;
        }

        return currentRecord;
    }

    /*
        @notice Atomically delete record of recordId by the caller.
        @dev Only of owners of the recordId can delete the record.
        @param recordId The id of the record to be deleted.
    */
    function deleteUserRecord(uint256 recordId)
        external
        ownerOrOperator(records[recordId].owner)
        expiredRecord(recordId)
    {
        uint256 tokenId = records[recordId].tokenId;

        frozen[records[recordId].owner][tokenId] -= records[recordId].amount;
        EnumerableSet.remove(usersToRecordsSet[records[recordId].user][tokenId], recordId);

        emit DeleteUserRecord(recordId);
    }

    /*
        @notice Returns the usable amount of tokenId tokens by account.
        @param account The target account.
        @param tokenId The target token id.
        @return The amount of tokens that the target account is user of.
    */
    function usableBalanceOf(address account, uint256 tokenId)
        external
        view
        returns(uint256 usable)
    {
        uint len = EnumerableSet.length(usersToRecordsSet[account][tokenId]);
        uint i = 0;

        while (i < len) {
            uint256 recordId = EnumerableSet.at(usersToRecordsSet[account][tokenId], i);
            if (records[recordId].expiry >= block.timestamp) {
                usable += records[recordId].amount;
            }
            unchecked {
                i++;
            }
        }
        return usable;
    }

    /*
        @notice Returns the amount of frozen tokens of token type id by account.
        @param account The target account.
        @param tokenId The target token id.
        @return The amount of tokens that are blocked for the target account with target token id.
    */
    function frozenBalanceOf(address account, uint256 tokenId)
        external
        view
        returns(uint256)
    {
        return _getFrozen(account, tokenId);
    }

    /*
        @notice Returns the UserRecord of recordId.
        @param recordId The given record id.
        @return The details of the record with given id.
    */
    function userRecordOf(uint256 recordId)
        external
        view
        returns(UserRecord memory)
    {
        return records[recordId];
    }

    function _getFrozen(address account, uint256 tokenId)
        internal
        override
        view
        returns(uint256)
    {
        return frozen[account][tokenId];
    }

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
