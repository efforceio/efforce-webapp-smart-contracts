// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./ERC1155.sol";
import "./Vintages.sol";

abstract contract ERC5679 is ERC1155, Vintages {

    function safeMint(address, uint256, uint256, bytes calldata)
        external
        pure
    {
        revert(Errors.NOT_ALLOWED);
    }

    function safeMintBatch(address, uint256[] calldata, uint256[] calldata, bytes calldata)
        pure
        external
    {
        revert(Errors.NOT_ALLOWED);
    }

    function burn(address _from, uint256 _id, uint256 _amount, bytes[] calldata)
        external
        ownerOrOperator(_from)
    {
        balances[_id][_from] -= _amount;
        vintageIdToDetails[_id].totalCredits -= _amount;

        emit TransferSingle(
            msg.sender,
            _from,
            address(0),
            _id,
            _amount
        );
        emit VintageUpdatedCredits(_id, vintageIdToDetails[_id].totalCredits);
    }

    function burnBatch(address _from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata)
        external
        ownerOrOperator(_from)
    {
        for (uint256 i = 0; i < amounts.length; i++) {
            balances[ids[i]][_from] -= amounts[i];
            vintageIdToDetails[ids[i]].totalCredits -= amounts[i];
            emit VintageUpdatedCredits(ids[i], vintageIdToDetails[ids[i]].totalCredits);
        }
        emit TransferBatch(msg.sender, _from, address(0), ids, amounts);
    }

    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
        internal
    {
        balances[_id][_to] += _amount;

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
