// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/RolesModifier.sol";

contract PoolsProxy is RolesModifier {
    address public delegate;

    /*
        @param _rolesContract The address of the roles smart contract.
        @param _tokenContract The erc20 token address to be staked and unstaked.
        @param _implementation The address of the Pool's logic contract.
    */
    constructor(address _rolesContract, address _delegate)
        RolesModifier(_rolesContract)
    {
        delegate = _delegate;
    }

    /*
        @notice Update the address of the implementation (logic) Pools contract.
        @dev Can be called only by admins or contract owners.
        @param _implementation The address of the new Pool's logic contract.
    */
    function setDelegate(address _delegate)
        external
        adminOrOwner(msg.sender)
    {
        delegate = _delegate;
    }

    /*
      @dev Fallback function allowing to perform a delegatecall to the given implementation.
        This function will return whatever the implementation call returns.
    */
    fallback () external {
        require(delegate != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), sload(delegate.slot), ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
