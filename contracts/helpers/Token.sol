// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract Token is ERC20Base {

    constructor(
        string memory _name,
        string memory _symbol
    )
        ERC20Base(msg.sender, _name, _symbol)
    {}

    function mint(uint amount) external {
        mintTo(msg.sender, amount);
    }
}
