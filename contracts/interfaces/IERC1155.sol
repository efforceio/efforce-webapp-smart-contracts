// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155 {

    /*
        @notice Transfers _value amount of an _id from the _from address to the _to address specified (with safety call).
        @dev The transaction must be reverted if the receiver is not allowed.
        @param _from The account form which the tokens will be transferred.
        @param _to The account which will receive the tokens.
        @param _id The id of the tokens that will be transferred.
        @param _value The amount of token that will be transferred.
        @param data Information that will be passed to the receiver if it is a smart contract.
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata data) external;

    /*
        @notice Transfers _values amount(s) of _ids from the _from address to the _to address specified (with safety call).
        @dev The transaction must be reverted if the receiver is not allowed.
        @param _from The account form which the tokens will be transferred.
        @param _to The account which will receive the tokens.
        @param _ids The id of the tokens that will be transferred.
        @param _values The amount of tokens that will be transferred.
        @param data Information that will be passed to the receiver if it is a smart contract.
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /*
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @param _operator The target address.
        @param _approved Set to true if the target address will be an operator, false otherwise.
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /*
        @notice Updates the uri returned by the uri(uint256 _id) function.
        @dev Can be invoked only by the contract owner.
        @param uri The new base uri.
    */
    function updateMetadataUri(string calldata uri) external;

    /*
        @notice Get the balance of an account's tokens.
        @param _owner The target account.
        @param _id The target token id.
        @return The amount of token owned by the target account having target id.
    */
    function balanceOf(address _owner, uint256 _id) external view returns(uint256);

    /*
        @notice Get the balance of multiple account/token pairs.
        @param _owners The target accounts.
        @param _ids The target token ids.
        @return The amount of token owned by each target account having the corresponding target id.
    */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns(uint256[] memory);

    /*
        @notice Queries the approval status of an operator for a given owner.
        @param _owner The NFTs owner.
        @param _operator Target account.
        @return True if the target account is the operator for NFTs owner, false otherwise.
    */
    function isApprovedForAll(address _owner, address _operator) external view returns(bool);

    /*
        @notice Returns a distinct Uniform Resource Identifier (URI) for a given token.
        @param _id Token id.
        @return The metadata uri for the given token id.
    */
    function uri(uint256 _id) external view returns(string memory);

    /*
        @notice Emitted when tokens are transferred, including zero value transfers as well as minting or burning.
        @param _operator The address that sent the transaction.
        @param _from The address from which tokens are transferred.
        @param _to The address that received the tokens.
        @param _id The id of the tokens that are transferred.
        @param _value The number of tokens that are transferred.
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /*
        @notice Emitted when tokens are transferred, including zero value transfers as well as minting or burning.
        @param _operator The address that sent the transaction.
        @param _from The address from which tokens are transferred.
        @param _to The address that received the tokens.
        @param _ids The id of the tokens that are transferred.
        @param _values The number of tokens that are transferred for each token id.
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /*
        @notice Emitted when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled)
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
