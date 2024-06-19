// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import "./modules/BankWrapper.sol";
import "./libraries/Errors.sol";
import "./helpers/IERC20.sol";
import "./interfaces/IBank.sol";

struct Lock {
    uint startTimestamp;
    uint endTimestamp;
    uint amount;
}

contract Locking is BankWrapper {
    mapping(uint id => Lock) private idToLock;
    mapping(address => uint lastLockId) private addressToLock;
    uint private lastId;
    uint public totalLocked;

    modifier hasLock(address account) {
        require(addressToLock[account] > 0, Errors.NOT_EXISTS);
        _;
    }

    modifier lockExists(uint id) {
        require(id > 0 && id <= lastId, Errors.NOT_EXISTS);
        _;
    }

    modifier lockOpen(address account) {
        require(idToLock[addressToLock[account]].endTimestamp == 0, Errors.NO_VALID_LOCK);
        _;
    }

    /*
        @notice Sets the address for the Bank contracts.
        @dev This function throws an error if the bank address is already initialized.
        @param _bankContract The address of the bank smart contract.
        @param _tokenAddress The address of the ERC20 token that can be locked.
    */
    function initializer(address _bankContract, address _tokenAddress) public {
        require(_bankContract != address(0), Errors.IS_ZERO_ADDRESS);
        require(_tokenAddress != address(0), Errors.IS_ZERO_ADDRESS);
        require(tokenAddress == address(0) && bankContract == address(0), Errors.NOT_ALLOWED);

        tokenAddress = _tokenAddress;
        bankContract = _bankContract;
    }

    /*
        @notice Transfers the amount to the bank contract and create a lock object.
        @param amount The amount of tokens to be locked.
    */
    function lock(uint amount) public {
        IERC20(tokenAddress).transferFrom(msg.sender, bankContract, amount);

        lastId++;
        idToLock[lastId] = Lock(block.timestamp, 0, amount);
        addressToLock[msg.sender] = lastId;
        unchecked {
            totalLocked += amount;
        }
        emit FundsLocked(lastId, msg.sender, amount);
    }

    /*
        @notice Transfer locked funds from the bank contract to the caller and set locking end timestamp.
        @dev The Lock contract address must be an admin for the bank contract.
    */
    function unlock()
        public
        hasLock(msg.sender)
        lockOpen(msg.sender)
    {
        uint lockId = addressToLock[msg.sender];
        idToLock[lockId].endTimestamp = block.timestamp;
        IBank(bankContract).withdraw(msg.sender, idToLock[lockId].amount, tokenAddress);
        unchecked {
            totalLocked -= idToLock[lockId].amount;
        }
        emit FundsUnlocked(lockId, msg.sender);
    }

    /*
        @notice Gets the lock details for a given id. If the id does not exists, it throws an error.
        @param id The id of the lock.
        @return The lock details.
    */
    function getLock(uint id)
        public
        view
        lockExists(id)
        returns(Lock memory)
    {
        return idToLock[id];
    }

    /*
        @notice Gets the last lock for the given account. If the account has no locking, it throws an error.
        @param account The target account.
        @return The lock details.
    */
    function getLastLockForAccount(address account)
        public
        view
        hasLock(account)
        returns(Lock memory)
    {
        return idToLock[addressToLock[account]];
    }

    /*
        @notice Emitted when an account locks funds.
        @param id The id of the lock.
        @param account The account that locked the funds.
        @param amount The amount of tokens locked.
        @parma startTimestamp The timestamp when the lock started.
    */
    event FundsLocked(uint indexed id, address indexed account, uint amount);

    /*
        @notice Emitted when an account unlocks funds.
        @param id The id of the lock.
        @param account The account that unlocked the funds.
        @parma endTimestamp The timestamp when the lock ended.
    */
    event FundsUnlocked(uint indexed id, address indexed account);
}
