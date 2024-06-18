// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import "./modules/BankWrapper.sol";
import "./libraries/Errors.sol";

struct Lock {
    uint startTimestamp;
    uint endTimestamp;
    uint amount;
}

contract Locking is BankWrapper {
    mapping(uint id => Lock) private idToLock;
    mapping(address => uint lastLockId) private addressToLock;

    /*
        @notice Sets the address for the Bank contracts.
        @dev This function throws an error if the bank address is already initialized
        @param _bankContract The address of the bank smart contract.
    */
    function initializer(address _bankContract) public {
        require(_bankContract != address(0), Errors.IS_ZERO_ADDRESS);

        tokenAddress = IBank(_bankContract).tokenAddress();
        bankContract = _bankContract;
    }
}
