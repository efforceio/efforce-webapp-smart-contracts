// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../interfaces/IRoles.sol";
import "../libraries/Errors.sol";

contract RolesModifier {
    address public rolesAddress;

    /*
        @notice Set the address of the roles smart contract Address.
        @dev This function must be called only if rolesAddress is set to zero address.
        @param _rolesAddress The address of the roles smart contract.
    */
    function rolesModifierInitializer(address _rolesAddress) internal {
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
