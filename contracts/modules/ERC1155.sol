// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./Accounts.sol";
import "../helpers/IERC1155TokenReceiver.sol";
import "../libraries/Constants.sol";
import "../libraries/Errors.sol";
import "../libraries/Utils.sol";
import "../interfaces/IERC1155.sol";

abstract contract ERC1155 is Accounts, IERC1155 {
    mapping (uint256 => mapping(address => uint256)) internal balances;
    mapping (address => mapping(address => bool)) private operatorApproval;
    string private baseUri;
    address private swapOperator;

    /*
        @param metadataUri Base uri for tokens metadata.
    */
    constructor(string memory metadataUri) {
        baseUri = metadataUri;
    }

    /*
        @notice Throws an error if the target account is not the sender of the transaction or approved by the sender.
        @param account Target account for which the sender is willing to transfer the token.
    */
    modifier ownerOrOperator(address account) {
        require(
            account == msg.sender ||
            operatorApproval[account][msg.sender] ||
            account == swapOperator,
            Errors.NOT_OWNER_OR_OPERATOR);
        _;
    }

    /*
        @notice Throws an error if the target account has not the given value of the given nft.
        @param account Target account.
        @param value The amount of token of given id.
        @param tokenId The id of the token.
    */
    modifier hasValue(address account, uint256 value, uint256 tokenId) {
        require(
            balances[tokenId][account] - _getFrozen(account, tokenId) >= value,
            Errors.INSUFFICIENT_BALANCE
        );
        _;
    }

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
    )
        external
        override
        accountEnabled(_to)
        ownerOrOperator(_from)
    {
        _doTransfer(_id, _from, _value, _to);
        _checkIfContract(_from, _to, _id, _value, data);
        emit TransferSingle(msg.sender, _from, _to, _id, _value);
    }

    /*
        @notice Transfers _values amount(s) of _ids from the _from address to the _to address specified
            (with safety call).
        @dev The transaction must be reverted if the receiver is not allowed.
        @param _from The account form which the tokens will be transferred.
        @param _to The account which will receive the tokens.
        @param _ids The id of the tokens that will be transferred.
        @param _values The amount of tokens that will be transferred.
        @param data Information that will be passed to the receiver if it is a smart contract.
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    )
        external
        accountEnabled(_to)
        ownerOrOperator(_from)
    {
        require(_ids.length == _values.length, Errors.NOT_MATCHING_LENGTHS);

        for (uint256 i = 0; i < _ids.length; ++i) {
            _doTransfer(_ids[i], _from, _values[i], _to);
        }

        if (Utils.isContract(_to)) {
            require(
                IERC1155TokenReceiver(_to).onERC1155BatchReceived(
                    msg.sender,
                    _from,
                    _ids,
                    _values,
                    _data
                ) == Constants.ERC1155_BATCH_ACCEPTED,
                Errors.UNKNOWN_VALUE_FROM_SAFE_TRANSFER
            );
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
    }

    /*
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @param _operator The target address.
        @param _approved Set to true if the target address will be an operator, false otherwise.
    */
    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /*
        @notice Set the swap operator.
        @param _swapOperator The address of the swap contract.
    */
    function setSwapOperator(address _swapOperator)
        external
        adminOrOwner(msg.sender)
    {
        swapOperator = _swapOperator;
    }

    /*
        @notice Updates the uri returned by the uri(uint256 _id) function.
        @dev Can be invoked only by the contract owner.
        @param uri The new base uri.
    */
    function updateMetadataUri(string calldata _uri)
        external
        adminOrOwner(msg.sender)
    {
        baseUri = _uri;
        emit MetadataUriUpdated(_uri);
    }

    /*
        @notice Get the balance of an account's tokens.
        @param _owner The target account.
        @param _id The target token id.
        @return The amount of token owned by the target account having target id.
    */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns(uint256)
    {
        return balances[_id][_owner];
    }

    /*
        @notice Get the balance of multiple account/token pairs.
        @param _owners The target accounts.
        @param _ids The target token ids.
        @return The amount of token owned by each target account having the corresponding target id.
    */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns(uint256[] memory)
    {
        require(_owners.length == _ids.length, Errors.NOT_MATCHING_LENGTHS);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /*
        @notice Queries the approval status of an operator for a given owner.
        @param _owner The NFTs owner.
        @param _operator Target account.
        @return True if the target account is the operator for NFTs owner, false otherwise.
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns(bool)
    {
        return operatorApproval[_owner][_operator];
    }

    /*
        @notice Returns a distinct Uniform Resource Identifier (URI) for a given token.
        @param _id Token id.
        @return The metadata uri for the given token id.
    */
    function uri(uint256)
        external
        view
        returns(string memory)
    {
        return baseUri;
    }

    function _doTransfer(uint256 _id, address _from, uint256 _value, address _to)
        private
        hasValue(_from, _value, _id)
    {
        balances[_id][_from] = balances[_id][_from] - _value;
        balances[_id][_to]   = _value + balances[_id][_to];
    }

    function _checkIfContract(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory data
    )
        internal
    {
        if (Utils.isContract(_to)) {
            require(
                IERC1155TokenReceiver(_to).onERC1155Received(
                    msg.sender,
                    _from,
                    _id,
                    _value,
                    data
                ) == Constants.ERC1155_ACCEPTED,
                Errors.UNKNOWN_VALUE_FROM_SAFE_TRANSFER
            );
        }
    }

    function _getFrozen(address, uint256)
        internal
        virtual
        view
        returns(uint256);

    /*
        @notice Emitted when tokens are transferred, including zero value transfers as well as minting or burning.
        @param _operator The address that sent the transaction.
        @param _from The address from which tokens are transferred.
        @param _to The address that received the tokens.
        @param _id The id of the tokens that are transferred.
        @param _value The number of tokens that are transferred.
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /*
        @notice Emitted when tokens are transferred, including zero value transfers as well as minting or burning.
        @param _operator The address that sent the transaction.
        @param _from The address from which tokens are transferred.
        @param _to The address that received the tokens.
        @param _ids The id of the tokens that are transferred.
        @param _values The number of tokens that are transferred for each token id.
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /*
        @notice Emitted when approval for a second party/operator address to manage all tokens for an owner address
            is enabled or disabled (absence of an event assumes disabled)
        @param _owner The owner of the NFTs.
        @param _operator The target address.
        @param _approved True if the target address is set as operator, false otherwise.
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /*
        @notice Emitted when the metadata base URI is updated.
        @param uri The new base uri.
    */
    event MetadataUriUpdated(string uri);
}
