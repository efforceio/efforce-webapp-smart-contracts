// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IRoyalties.sol";
import "./Roles.sol";

abstract contract Royalties is IRoyalties, Roles {

    uint256 private royaltyBps;

    constructor(uint256 _royaltyBps) {
        royaltyBps = _royaltyBps;
    }

    function setRoyaltyInfo(
        uint256 _royaltyBps
    )
        external
        override
        contractOwner(msg.sender)
    {
        royaltyBps = _royaltyBps;
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        override
        returns(address, uint256)
    {
        return (address(this), (salePrice * royaltyBps) / 10_000);
    }

}
