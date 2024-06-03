// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./libraries/Errors.sol";
import "./modules/BankWrapper.sol";
import "./modules/RolesModifier.sol";
import "./helpers/IERC20.sol";
import "./interfaces/IBank.sol";

struct Pool {
    uint stakingStartedAt;
    uint allocated;
    bool canceled;
    uint stakingPeriod;
}

contract PoolsProxy is BankWrapper, RolesModifier {
    uint256 public numberOfPools;

    mapping(uint256=>Pool) private idToPool;
    mapping(address=>mapping(uint256=>uint256)) private addressToPoolStaking;
    mapping(uint256=>uint256) private poolToStaked;
    address public implementation;

    /*
        @param _rolesContract The address of the roles smart contract.
        @param _tokenContract The erc20 token address to be staked and unstaked.
        @param _implementation The address of the Pool's logic contract.
    */
    constructor(address _rolesContract, address _bankContract, address _implementation)
        BankWrapper(_bankContract)
        RolesModifier(_rolesContract)
    {
        implementation = _implementation;
    }

    /*
        @notice Update the address of the implementation (logic) Pools contract.
        @dev Can be called only by admins or contract owners.
        @param _implementation The address of the new Pool's logic contract.
    */
    function setImplementation(address _implementation)
        external
        adminOrOwner(msg.sender)
    {
        implementation = _implementation;
    }

    /*
      @dev Fallback function allowing to perform a delegatecall to the given implementation.
        This function will return whatever the implementation call returns.
    */
    function () payable public {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
