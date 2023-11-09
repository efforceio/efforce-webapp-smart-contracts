// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/Offers.sol";
import "./modules/Listings.sol";
import "./modules/BankWrapper.sol";
import "./helpers/IERC1155TokenReceiver.sol";

contract Swap is Offers, Listings, IERC1155TokenReceiver {

    address public immutable creditContract;

    constructor(address _creditContract, address _bankAddress)
        BankWrapper(_bankAddress)
    {
        creditContract = _creditContract;
    }

    function _getCreditsContract()
        internal
        override(Offers, Listings)
        view
        returns(address)
    {
        return creditContract;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        override
        pure
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        override
        pure
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function _positiveAmount(uint256 amount)
        internal
        pure
        override(Listings, Offers)
    {
        require(amount > 0, Errors.NOT_ENOUGH_CREDITS);
    }
}
