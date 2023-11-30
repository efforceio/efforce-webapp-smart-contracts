// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/Offers.sol";
import "./modules/Listings.sol";
import "./modules/BankWrapper.sol";
import "./helpers/IERC1155TokenReceiver.sol";
import "./libraries/Constants.sol";

contract Swap is Offers, Listings, IERC1155TokenReceiver {


    constructor(address _creditContract, address _bankAddress)
        BankWrapper(_bankAddress)
        Offers(_creditContract)
        Listings(_creditContract)
    {}

    function onERC1155Received(address, address, uint, uint, bytes calldata)
        external
        override
        pure
        returns(bytes4)
    {
        return Constants.ERC1155_ACCEPTED;
    }

    function onERC1155BatchReceived(address, address, uint[] calldata, uint256[] calldata, bytes calldata)
        external
        override
        pure
        returns(bytes4)
    {
        return Constants.ERC1155_BATCH_ACCEPTED;
    }

    function _positiveAmount(uint256 amount)
        internal
        pure
        override(Listings, Offers)
    {
        require(amount > 0, Errors.NOT_ENOUGH_CREDITS);
    }
}
