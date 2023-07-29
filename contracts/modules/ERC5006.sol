// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "../interfaces/IERC5006.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../libraries/Errors.sol";

abstract contract ERC5006 is IERC5006, ERC1155 {

    mapping(uint256 => UserRecord) private records;
    mapping(address => mapping(uint256 => uint256)) private frozen;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) private usersToRecordsSet;
    uint256 private currentRecord;

    constructor() {
        currentRecord = 0;
    }

    modifier expiredRecord(uint256 recordId) {
        require(records[recordId].expiry < block.timestamp, Errors.NOT_EXPIRED);
        _;
    }

    modifier recordExists(uint256 recordId) {
        require(
            EnumerableSet.contains(usersToRecordsSet[records[recordId].user][records[recordId].tokenId], recordId),
            Errors.NOT_EXISTS
        );
        _;
    }

    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint256 amount,
        uint256 expiry
    )
        external
        override
        ownerOrOperator(owner)
        accountEnabled(user)
        hasValue(owner, amount, tokenId)
        returns(uint256)
    {
        currentRecord++;

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

        return currentRecord;
    }

    function deleteUserRecord(
        uint256 recordId
    )
        external
        override
        ownerOrOperator(records[recordId].owner)
        recordExists(recordId)
        expiredRecord(recordId)
    {
        uint256 tokenId = records[recordId].tokenId;

        frozen[records[recordId].owner][tokenId] -= records[recordId].amount;
        EnumerableSet.remove(usersToRecordsSet[records[recordId].user][tokenId], recordId);

        emit DeleteUserRecord(recordId);
    }

    function usableBalanceOf(
        address account,
        uint256 tokenId
    )
        external
        view
        override
        returns(uint256)
    {
        uint256 usable = 0;
        for (uint256 i = 0; i < EnumerableSet.length(usersToRecordsSet[account][tokenId]); i++) {
            uint256 recordId = EnumerableSet.at(usersToRecordsSet[account][tokenId], i);
            if (records[recordId].expiry >= block.timestamp) {
                usable += records[recordId].amount;
            }
        }
        return usable;
    }

    function frozenBalanceOf(
        address account,
        uint256 tokenId
    )
        external
        view
        override
        returns(uint256)
    {
        return _getFrozen(account, tokenId);
    }

    function userRecordOf(
        uint256 recordId
    )
        external
        view
        returns(UserRecord memory)
    {
        return records[recordId];
    }

    function _getFrozen(address account, uint256 tokenId)
        internal
        virtual
        override
        view
        returns(uint256)
    {
        return frozen[account][tokenId];
    }

}
