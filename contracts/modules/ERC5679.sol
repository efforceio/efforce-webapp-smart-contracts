// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./ERC1155.sol";

abstract contract ERC5679 is ERC1155 {

    /*
        @notice Emits new credits.
        @dev Can be called only by admins or contract owner.
        @dev Vintage id must exist.
        @dev The receiver must be enabled.
        @param to The receiver.
        @param id The vintage id.
        @param amount The amount of credits to be minted.
        @data Will be passed as input if the receiver is a smart contract.
    */
    function safeMint(address to, uint256 id, uint256 amount, bytes calldata data)
        external
        override
        adminOrOwner(msg.sender)
        accountEnabled(to)
    {
        _mint(to, id, amount, data);
    }

    /*
        @notice Emits new credits.
        @dev Can be called only by admins or contract owner.
        @dev Vintage ids must exist.
        @dev The receiver must be enabled.
        @param to The receiver.
        @param ids The vintage ids.
        @param amounts The amounts of credits to be minted for each vintage id.
        @data Will be passed as input if the receiver is a smart contract.
    */
    function safeMintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data)
        adminOrOwner(msg.sender)
        accountEnabled(to)
        external
    {
        for (uint256 i = 0; i < ids.length; i++) {
            _mint(to, ids[i], amounts[i], data);
        }
    }

    /*
        @param Destroys owned credits.
        @param _from The owner of the credits.
        @param _id The vintage id.
        @param _amount The amount of credits to be destroyed.
    */
    function burn(address _from, uint256 _id, uint256 _amount, bytes calldata)
        external
        ownerOrOperator(_from)
    {
        _burn(_from, _id, _amount);

        emit TransferSingle(
            msg.sender,
            _from,
            address(0),
            _id,
            _amount
        );

    }

    /*
        @param Destroys owned credits.
        @param _from The owner of the credits.
        @param ids The vintage ids.
        @param amounts The amount of credits to be destroyed for each vintage id.
    */
    function burnBatch(address _from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata)
        external
        ownerOrOperator(_from)
    {
        for (uint256 i = 0; i < amounts.length; i++) {
            _burn(_from, ids[i], amounts[i]);
        }
        emit TransferBatch(msg.sender, _from, address(0), ids, amounts);
    }

    function _burn(address _from, uint256 _id, uint256 _amount)
        private
        isValidVintageId(_id)
    {
        balances[_id][_from] -= _amount;
        vintageIdToDetails[_id].totalCredits -= _amount;
        emit VintageUpdatedCredits(_id, vintageIdToDetails[_id].totalCredits);
    }

    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
        private
        isValidVintageId(_id)
    {
        balances[_id][_to] += _amount;

        vintageIdToDetails[_id].totalCredits += _amount;
        emit VintageUpdatedCredits(_id, vintageIdToDetails[_id].totalCredits);

        _checkIfContract(address(0), _to, _id, _amount, _data);

        emit TransferSingle(
            msg.sender,
            address(0),
            _to,
            _id,
            _amount
        );
    }
}
