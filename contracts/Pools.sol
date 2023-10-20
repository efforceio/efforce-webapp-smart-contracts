// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./interfaces/IRoles.sol";
import "./helpers/IERC20.sol";
import "./libraries/Errors.sol";

struct Pool {
    uint256 createdAt;
    uint256 lockStartedAt;
    string uri;
    uint256 distributed;
    bool canceled;
}

contract Pools {
    address immutable public rolesContract;
    address immutable public tokenContract;
    uint256 immutable public stakingPeriod;

    uint256 public numberOfPools;

    mapping(uint256=>Pool) private idToPool;
    mapping(address=>mapping(uint256=>uint256)) private addressToPoolStaking;
    mapping(uint256=>uint256) private poolToStaked;

    constructor(address _rolesContract, uint256 _stakingPeriod, address _tokenContract) {
        rolesContract = _rolesContract;
        stakingPeriod = _stakingPeriod;
        tokenContract = _tokenContract;
    }

    /*
        @notice Raise an error if the sender is not an Admin or contract owner.
    */
    modifier isAdminOrOwner() {
        require(
            IRoles(rolesContract).getOwner() == msg.sender ||
            IRoles(rolesContract).isAdmin(msg.sender),
            Errors.NOT_ALLOWED
        );
        _;
    }

    /*
        @notice Raise an error if the staking period already started.
        @param id The id of the target pool.
    */
    modifier canCancel(uint256 id) {
        require(idToPool[id].lockStartedAt == 0, Errors.NOT_ALLOWED);
        _;
    }

    /*
        @notice Raise an error if the staking period already started or if the pool is canceled.
        @param id The id of the target pool.
    */
    modifier canStartStaking(uint256 id) {
        require(
            idToPool[id].lockStartedAt == 0 && !idToPool[id].canceled,
            Errors.NOT_ALLOWED
        );
        _;
    }

    /*
        @notice Raise an error if the pool is canceled or the locking period already started.
    */
    modifier isStakingPeriod(uint256 id) {
        require(
            !idToPool[id].canceled &&
            idToPool[id].lockStartedAt == 0
        );
        _;
    }

    /*
        @notice Will not raise an error if one of the following conditions are met:
            the pool is canceled;
            the locking period ended and funds are allocated;
            the locking period is not started.
    */
    modifier isUnstakingPeriod(uint256 id) {
        require(
            idToPool[id].canceled ||
            (idToPool[id].lockStartedAt == 0 ||
                block.timestamp >= idToPool[id].lockStartedAt + stakingPeriod) &&
            idToPool[id].distributed > 0 ||
            idToPool[id].lockStartedAt == 0
        );
        _;
    }

    /*
        @notice Create a new pool.
        @dev Can be called only by admins or contract owners.
        @param uri URI to pool metadata.
    */
    function createPool(string calldata uri)
        external
        isAdminOrOwner()
    {
        idToPool[numberOfPools] = Pool(block.timestamp, 0, uri, 0, false);
        emit PoolCreated(numberOfPools, uri);
        numberOfPools++;
    }

    /*
        @notice Starts the staking period. Funds are locked for the stakingPeriod and users cannot stack new funds.
        @dev Can be called only by admins or contract owners.
        @dev Can be called only if the staking period is not started and the pool is not canceled.
        @param id The id of the target pool.
    */
    function startLockingPeriod(uint256 id)
        external
        isAdminOrOwner()
        canStartStaking(id)
    {
        idToPool[id].lockStartedAt = block.timestamp;
        emit PoolChangedState(id, 0);
    }

    /*
        @notice Cancels a pool.
        @dev Can be called only by contract owner or admins.
        @dev Can be called only if the staking period is not already started.
        @param id The target pool id.
    */
    function cancelPool(uint256 id)
        external
        isAdminOrOwner()
        canCancel(id)
    {
        idToPool[id].canceled = true;
        emit PoolChangedState(id, 1);
    }

    /*
        @notice Allocates the total refund for a pool.
        @dev Can be called only by contract owner or admins.
        @param id The id of the target pool.
        @param distribution The refund amount allocated for the pool.
    */
    function setDistributionForPool(uint256 id, uint256 distribution)
        external
        isAdminOrOwner()
    {
        idToPool[id].distributed = distribution;
        emit PoolChangedState(id, 2);
    }

    /*
        @notice Stake the funds for target pool.
            The function will transfer the amount from the caller to this smart contract.
        @dev Can be called if the pool has an active staking period and is not canceled.
        @param id The id of the target pool.
        @param amount The amount to be staked in the pool.
    */
    function stake(uint256 id, uint256 amount)
        external
        isStakingPeriod(id)
    {
        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
        addressToPoolStaking[msg.sender][id] = amount;
        poolToStaked[id] += amount;
        emit Locking(msg.sender, id, amount, true);
    }

    /*
        @notice Stake the funds for target pool in behalf of the given account.
            This function will not transfer funds to the smart contract.
        @dev Can be called only by contract owner or admins.
        @dev Can be called if the pool has an active staking period and is not canceled.
        @param id The id of the target pool.
        @param amount The amount to be staked in the pool.
        @param account The account that will benefit from the staking.
    */
    function stakingFor(uint256 id, uint256 amount, address account)
        external
        isStakingPeriod(id)
        isAdminOrOwner()
    {
        addressToPoolStaking[msg.sender][id] = amount;
        poolToStaked[id] += amount;
        emit Locking(msg.sender, id, amount, true);
    }

    /*
        @notice Unlocks funds from the smart contract.
            If the unstake is done after the locking period ended, it will return the staked amount plus interests,
            otherwise it will return the exact amount that was staked.
        @dev Can be called if the pool is canceled, the locking period ended or is not started.
        @param id The id of the target pool.
    */
    function unstake(uint256 id)
        external
        isUnstakingPeriod(id)
    {
        uint256 amount = addressToPoolStaking[msg.sender][id];
        if (idToPool[id].lockStartedAt > 0) {
            uint256 amountWithInterests = (
                addressToPoolStaking[msg.sender][id] * idToPool[id].distributed
            ) / poolToStaked[id];
            IERC20(tokenContract).transfer(
                msg.sender,
                amountWithInterests
            );
            emit Locking(msg.sender, id, amountWithInterests, false);
        } else {
            IERC20(tokenContract).transfer(msg.sender, amount);
            poolToStaked[id] -= amount;
            emit Locking(msg.sender, id, amount, false);
        }
        addressToPoolStaking[msg.sender][id] = 0;
    }

    /*
        @notice Withdraw funds from the smart contract.
        @dev Can be called only by contract owner or admins.
        @param amount The amount to be withdrawn.
        @param to The address that will receive the funds.
    */
    function withdraw(uint256 amount, address to)
        external
        isAdminOrOwner()
    {
        IERC20(tokenContract).transfer(to, amount);
        emit Withdrawal(amount, to, msg.sender);
    }

    /*
        @param id The id of the target pool.
        @return The pool details as Pool struct.
    */
    function getPool(uint256 id)
        external
        view
        returns(Pool memory)
    {
        return idToPool[id];
    }

    /*
        @param id The id of the target pool.
        @param account The target account.
        @return The amount locked for the target pool and account.
    */
    function getLockedAmount(uint256 id, address account)
        external
        view
        returns(uint256)
    {
        return addressToPoolStaking[account][id];
    }

    /*
        @param id The id of the target pool.
        @return The total amount locked for the target pool.
    */
    function getStakedAmount(uint256 id)
        external
        view
        returns(uint256)
    {
        return poolToStaked[id];
    }

    /*
        @notice Emitted when an account locks or unlocks some funds in a pool.
        @param account The target account.
        @param id The id of the target pool.
        @param amount The amount that is locked or unlocked.
        @param isLocking If the target account is locking funds, it is set to true, otherwise false.
    */
    event Locking(address account, uint256 id, uint256 amount, bool isLocking);

    /*
        @notice Emitted when the contract owner or admins withdraw funds from the smart contract.
        @param amount The amount of funds that have been withdrawn.
        @param to The receiver of such funds.
        @param sender The address that called the function.
    */
    event Withdrawal(uint256 amount, address to, address sender);

    /*
        @notice Emitted when a new pool is created.
        @param id The id of the newly created pool.
        @param uri The URI of the pool's metadata.
    */
    event PoolCreated(uint256 id, string uri);

    /*
        @notice Emitted when the status of the Pool is updated.
        @param id The id of the target pool.
        @param state The new state of the pool. Possible states are:
            0 –> Locking period.
            1 –> Pool canceled.
            2 –> Pool funded for refund.
    */
    event PoolChangedState(uint256 id, uint8 state);
}
