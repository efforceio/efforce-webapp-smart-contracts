// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../interfaces/IRoles.sol";
import "../libraries/Errors.sol";

contract RolesModifier {
    address immutable public rolesAddress;

    constructor(address _rolesAddress) {
        rolesAddress = _rolesAddress;
    }

    modifier adminOrOwner(address account) {
        require(
            IRoles(rolesAddress).getOwner() == account ||
            IRoles(rolesAddress).isAdmin(account),
            Errors.NOT_ALLOWED
        );
        _;
    }

}
