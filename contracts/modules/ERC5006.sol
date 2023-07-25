// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "../interfaces/IERC5006.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../libraries/Errors.sol";

contract ERC5006 is IERC5006, ERC1155 {
    mapping(uint256 => UserRecord) private records;
    mapping(address => mapping(uint256 => uint256)) private frozen;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) private usersToRecordsSet;
    uint256 private currentRecord;

    constructor(
        address owner,
        string memory metadataUri
    ) ERC1155(owner, metadataUri) {
        currentRecord = 0;
    }

    modifier expiredRecord(uint256 recordId) {
        require(records[recordId].expiry < block.timestamp, Errors.NOT_EXPIRED);
        _;
    }

    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint64 amount,
        uint64 expiry
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
        accountsToRecordsSet[user][tokenId].add(currentRecord);

        emit CreateUserRecord(recordId, tokenId, amount, owner, user, expiry);

        return currentRecord;
    }

    function deleteUserRecord(
        uint256 recordId
    )
        external
        override
        ownerOrOperator(records[recordId].owner)
        expiredRecord(recordId)
    {
        frozen[owner][tokenId] -= records[recordId].amount;
        accountsToRecordsSet[records[recordId].user][tokenId].remove(recordId);

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
        for (uint256 i = 0; i < usersToRecordsSet[account][tokenId].length; i++) {
            if (records[usersToRecordsSet[account][tokenId][i]].expiry >= block.timestamp) {
                usable += records[usersToRecordsSet[account][tokenId][i]].amount;
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
        returns(UserRecord)
    {
        return records[recordId];
    }

    function _getFrozen(address account, uint256 tokenId)
        internal
        virtual
        override
        returns(uint256)
    {
        return frozen[account][tokenId];
    }

}
