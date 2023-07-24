// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC1155.sol";
import "./Accounts.sol";
import "../helpers/IERC1155TokenReceiver.sol";
import "../libraries/Constants.sol";
import "../libraries/Errors.sol";
import "../libraries/Utils.sol";

contract ERC1155 is IERC1155, Accounts {

    mapping (uint256 => mapping(address => uint256)) private balances;
    mapping (address => mapping(address => bool)) private operatorApproval;
    string private uri;

    constructor(
        address owner,
        string memory metadataUri
    ) Accounts(owner) {
        uri = metadataUri;
    }

    modifier ownerOrOperator(address account) {
        require(account == msg.sender || operatorApproval[account][msg.sender], Errors.NOT_OWNER_OR_OPERATOR);
        _;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata data
    )
        external
        override
        accountEnabled(_to)
        ownerOrOperator(_from)
    {
        balances[_id][_from] = balances[_id][_from] - _value;
        balances[_id][_to]   = _value + balances[_id][_to];

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (Utils.isContract(_to)) {
            require(
                IERC1155TokenReceiver(_to).onERC1155Received(
                    _operator,
                    _from,
                    _id,
                    _value,
                    _data
                ) == Constants.ERC1155_ACCEPTED,
                Errors.UNKNOWN_VALUE_FROM_SAFE_TRANSFER
            );
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    )
        external
        override
        accountEnabled(_to)
        ownerOrOperator(_from)
    {
        require(_ids.length == _values.length, Errors.NOT_MATCHING_LENGTHS);
        for (uint256 i = 0; i < _ids.length; ++i) {
            balances[_ids[i]][_from] = balances[_ids[i]][_from] - _values[i];
            balances[_ids[i]][_to]   = _values[i] + balances[_ids[i]][_to];
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (Utils.isContract(_to)) {
            require(
                IERC1155TokenReceiver(_to).onERC1155BatchReceived(
                    _operator,
                    _from,
                    _ids,
                    _values,
                    _data
                ) == Constants.ERC1155_BATCH_ACCEPTED,
                Errors.UNKNOWN_VALUE_FROM_SAFE_TRANSFER
            );
        }
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        override
    {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function updateMetadataUri(
        string calldata _uri
    )
        external
        override
        contractOwner(msg.sender)
    {
        uri = _uri;
        emit MetadataUriUpdated(_uri);
    }

    function balanceOf(
        address _owner,
        uint256 _id
    )
        external
        view
        override
        returns(uint256)
    {
        return balances[_id][_owner];
    }

    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    )
        external
        view
        override
        returns(uint256[] memory)
    {
        require(_owners.length == _ids.length, Errors.NOT_MATCHING_LENGTHS);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    )
        external
        view
        override
        returns(bool)
    {
        return operatorApproval[_owner][_operator];
    }

    function uri(
        uint256
    )
        external
        view
        override
        returns(string memory)
    {
        return uri;
    }

}
