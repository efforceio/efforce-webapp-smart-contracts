// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/Offers.sol";
import "./modules/Listings.sol";

contract Marketplace is Offers, Listings {

    address public immutable creditContract;

    constructor(address _creditContract, address _tokenAddress, address _rolesAddress)
        Bank(_tokenAddress)
        RolesModifier(_rolesAddress)
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
}
