// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./modules/BankWrapper.sol";
import "./modules/RolesModifier.sol";
import "./helpers/IERC20.sol";
import "./interfaces/ILocking.sol";

struct Pool {
    uint stakingStartedAt;
    uint allocated;
    bool canceled;
    uint stakingPeriod;
}

contract Pools is BankWrapper, RolesModifier {
    uint256 public numberOfPools;
    mapping(uint256=>Pool) private idToPool;
    mapping(address=>mapping(uint256=>uint256)) private addressToPoolStaking;
    mapping(uint256=>uint256) private poolToStaked;
    mapping (uint poolId => mapping(address account => address delegated)) private poolToDelegation;
    mapping (address delegated => address delegator) private delegatedToDelegator;
    address public lockingContract;

    uint[] private lockingSteps = [2500000000000000000000000000000000, 5000000000000000000000000000000000];
    uint[] private discounts = [10, 15];
    uint private constant baseFee = 20;

    /*
        @notice Sets the address for the Role and Bank contracts.
        @dev This function throws an error if the addresses are already initialized
        @param _rolesContract The address of the roles smart contract.
        @param _bankContract The address of the bank smart contract.
    */
    function initializer(address _rolesAddress, address _bankContract, address _lockingContract) external {
        require(
            rolesAddress == address(0) && bankContract == address(0) && lockingContract == address(0),
            Errors.NOT_ALLOWED
        );
        require(
            _rolesAddress != address(0) && _bankContract != address(0) && _lockingContract != address(0),
            Errors.IS_ZERO_ADDRESS
        );

        rolesAddress = _rolesAddress;
        tokenAddress = IBank(_bankContract).tokenAddress();
        bankContract = _bankContract;
        lockingContract = _lockingContract;
    }

    /*
        @notice Raise an error if the staking period already started.
        @param id The id of the target pool.
    */
    modifier canCancel(uint256 id) {
        require(idToPool[id].stakingStartedAt == 0, Errors.POOL_IS_OPEN);
        _;
    }

    /*
        @notice Raise an error if the staking period already started or if the pool is canceled.
        @param id The id of the target pool.
    */
    modifier canStartStaking(uint256 id) {
        require(
            idToPool[id].stakingStartedAt == 0 && !idToPool[id].canceled, Errors.POOL_IS_OPEN);
        _;
    }

    /*
        @notice Raise an error if the pool is canceled or the staking period already started.
    */
    modifier isStakingPeriod(uint256 id) {
        require(
            !idToPool[id].canceled && idToPool[id].stakingStartedAt == 0, Errors.STAKING_NOT_ALLOWED);
        _;
    }

    /*
        @notice Will not raise an error if one of the following conditions are met:
            the pool is canceled;
            the staking period ended and funds are allocated;
            the staking period is not started.
        @param id The id of the pool.
        @param rewardPeriodOnly Return true only if the pool is not canceled.
    */
    modifier isUnstakingPeriod(uint256 id, bool rewardPeriodOnly) {
        require(
            idToPool[id].canceled && !rewardPeriodOnly ||
            block.timestamp >= idToPool[id].stakingStartedAt + idToPool[id].stakingPeriod && idToPool[id].allocated > 0,
            Errors.FUNDS_LOCKED
        );
        _;
    }

    /*
        @notice Will raise an error if the pool is already allocated.
    */
    modifier poolNotAllocated(uint256 id) {
        require(idToPool[id].allocated == 0, Errors.NOT_ALLOCATED);
        _;
    }

    /*
        @notice Will raise an error if:
            - The pool already has a delegation for given delegator;
            - The delegated created a delegation for that pool;
            - The delegator address is the same address of the delegated;
            - The delegated address is already delegated.
    */
    modifier canDelegate(uint poolId, address delegator, address delegated) {
        require(poolToDelegation[poolId][delegator] == address(0), Errors.NOT_ALLOWED);
        require(poolToDelegation[poolId][delegated] == address(0), Errors.NOT_ALLOWED);
        require(delegator != delegated, Errors.SAME_ADDRESS);
        require(delegatedToDelegator[delegated] == address(0), Errors.NOT_ALLOWED);
        _;
    }

    /*
        @notice Will raise an error if the delegator address has no active delegations for given pool.
    */
    modifier hasDelegation(uint poolId, address delegator) {
        require(poolToDelegation[poolId][delegator] != address(0), Errors.NOT_EXISTS);
        _;
    }

    /*
        @notice Create a new pool.
        @dev Can be called only by admins or contract owners.
        @param stakingPeriod The locking period expressed in seconds.
    */
    function createPool(uint256 stakingPeriod)
        external
        adminOrOwner(msg.sender)
    {
        idToPool[numberOfPools] = Pool(0, 0, false, stakingPeriod);
        emit PoolCreated(numberOfPools, stakingPeriod);
        numberOfPools++;
    }

    /*
        @notice Starts the staking period. Funds are staked for the stakingPeriod and users cannot stack new funds.
        @dev Can be called only by admins or contract owners.
        @dev Can be called only if the staking period is not started and the pool is not canceled.
        @param id The id of the target pool.
    */
    function startStakingPeriod(uint256 id)
        external
        adminOrOwner(msg.sender)
        canStartStaking(id)
    {
        idToPool[id].stakingStartedAt = block.timestamp;
        emit PoolChangedState(id, 0, 0);
    }

    /*
        @notice Cancels a pool.
        @dev Can be called only by contract owner or admins.
        @dev Can be called only if the staking period is not already started.
        @param id The target pool id.
    */
    function cancelPool(uint256 id)
        external
        adminOrOwner(msg.sender)
        canCancel(id)
    {
        idToPool[id].canceled = true;
        emit PoolChangedState(id, 1, 0);
    }

    /*
        @notice Allocates the total refund for a pool.
        @dev Can be called only by contract owner or admins.
        @param id The id of the target pool.
        @param distribution The refund amount allocated for the pool.
    */
    function setDistributionForPool(uint256 id, uint256 allocated)
        external
        adminOrOwner(msg.sender)
        poolNotAllocated(id)
    {
        idToPool[id].allocated = allocated;
        emit PoolChangedState(id, 2, allocated);
    }

    /*
        @notice Stake the funds for target pool.
            The function will transfer the amount from the caller to this smart contract.
        @dev Can be called if the pool has an active staking period and is not canceled.
        @param id The id of the target pool.
        @param amount The amount to be staked in the pool.
    */
    function stake(uint256 id, uint256 amount) external {
        IERC20(tokenAddress).transferFrom(msg.sender, bankContract, amount);
        _stake(id, amount, msg.sender);
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
    function stakeFor(uint256 id, uint256 amount, address account)
        external
        adminOrOwner(msg.sender)
    {
        _stake(id, amount, account);
    }

    function _stake(uint256 id, uint256 amount, address account)
        private
        isStakingPeriod(id)
    {
        addressToPoolStaking[account][id] += amount;
        poolToStaked[id] += amount;
        emit Staking(account, msg.sender, id, amount, true);
    }

    /*
        @notice Unstakes funds from the smart contract.
            If the unstake is done after the staking period ended, it will return the staked amount plus interests,
            otherwise it will return the exact amount that was staked.
        @dev Can be called if the pool is canceled, the staking period ended or is not started.
        @param id The id of the target pool.
    */
    function unstake(uint256 id)
        external
        isUnstakingPeriod(id, false)
    {
        uint256 amount = addressToPoolStaking[msg.sender][id];
        if (idToPool[id].stakingStartedAt > 0) {
            uint256 distribution = (
                addressToPoolStaking[msg.sender][id] * idToPool[id].allocated
            ) / poolToStaked[id];

            uint netDistribution = getNetDistributionForPoolAndAccount(id, msg.sender, distribution);
            IBank(bankContract).withdraw(msg.sender, netDistribution);
            emit Staking(msg.sender, msg.sender, id, netDistribution, false);
        } else {
            IBank(bankContract).withdraw(msg.sender, amount);
            emit Staking(msg.sender, msg.sender, id, amount, false);
        }
        addressToPoolStaking[msg.sender][id] = 0;
    }

    function withdrawDelegationRewards(uint id)
        external
        view
        isUnstakingPeriod(id, true)
    {

    }

    /*
        @notice Delegate fee discount for account.
        @dev Can be called only if no previous delegation was set for pool with given id.
        @param poolId The id of the target pool.
        @param account The account to be delegated.
    */
    function delegate(uint poolId, address account)
        external
        canDelegate(poolId, msg.sender, account)
    {
        poolToDelegation[poolId][msg.sender] = account;
        emit DelegationAdded(poolId, msg.sender, account);
    }

    function getNetDistributionForPoolAndAccount(uint poolId, address account, uint distribution)
        internal
        view
        returns(uint)
    {
        uint baseReward = distribution * (100 - baseFee) / 100;
        uint discount = 0;


        // If the input account was delegated
        if (delegatedToDelegator[account] != address(0)) {
            try ILocking(lockingContract).getLastLockForAccount(delegatedToDelegator[account]) returns (Lock memory delegatorLock) {
                // If the delegator has an active lock that started before the staking period and is still open
                if (delegatorLock.startTimestamp <= idToPool[poolId].stakingStartedAt && delegatorLock.endTimestamp == 0) {
                    if (delegatorLock.amount >= lockingSteps[0] && delegatorLock.amount < lockingSteps[1]) {
                        discount = (distribution * discounts[0] / 100) / 2;
                    }
                    if (delegatorLock.amount > lockingSteps[1]) {
                        discount = (distribution * discounts[1] / 100) / 2;
                    }
                }
            } catch {}
        }

        // If the account has an active lock, it execute the code in the brackets.
        try ILocking(lockingContract).getLastLockForAccount(account) returns (Lock memory accountLock) {
            // Apply the discount if the account has an active lock and it has no delegations.
            if (
                accountLock.startTimestamp <= idToPool[poolId].stakingStartedAt &&
                accountLock.endTimestamp == 0 &&
                poolToDelegation[poolId][account] == address(0)
            ) {
                if (accountLock.amount >= lockingSteps[0] && accountLock.amount < lockingSteps[1]) {
                    discount = distribution * discounts[0] / 100;
                }
                if (accountLock.amount > lockingSteps[1]) {
                    discount = distribution * discounts[1] / 100;
                }
            }
        } catch {}

        return baseReward + discount;
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
        @return The amount staked for the target pool and account.
    */
    function getStakedAmountForPoolAndAccount(uint256 id, address account)
        external
        view
        returns(uint256)
    {
        return addressToPoolStaking[account][id];
    }

    /*
        @param id The id of the target pool.
        @return The total amount staked for the target pool.
    */
    function getStakedAmountForPool(uint256 id)
        external
        view
        returns(uint256)
    {
        return poolToStaked[id];
    }

    /*
        @notice Return the delegated account for given delegator and pool.
        @dev Fails if the delegator has not delegations for the given pool.
        @param poolId The id of the pool.
        @param delegator The address of the delegator.
    */
    function getDelegation(uint poolId, address delegator)
        external
        view
        hasDelegation(poolId, delegator)
        returns(address)
    {
        return poolToDelegation[poolId][delegator];
    }

    /*
        @notice Emitted when an account stakes or unstakes some funds in a pool.
        @param account The target account.
        @param id The id of the target pool.
        @param amount The amount that is staked or unstaked.
        @param isStaking If the target account is staking funds, it is set to true, otherwise false.
    */
    event Staking(address indexed account, address sender, uint256 indexed id, uint256 amount, bool indexed isStaking);

    /*
        @notice Emitted when a new pool is created.
        @param id The id of the newly created pool.
    */
    event PoolCreated(uint256 id, uint256 stakingPeriod);

    /*
        @notice Emitted when the status of the Pool is updated.
        @param id The id of the target pool.
        @param state The new state of the pool. Possible states are:
            0 –> Staking period.
            1 –> Pool canceled.
            2 –> Pool funded for refund.
        @param amount The funded amount if state is 2, 0 otherwise.
    */
    event PoolChangedState(uint256 indexed id, uint256 indexed state, uint256 amount);

    /*
        @notice Emitted when a new delegation is created.
        @param poolId The id of the target pool.
        @param delegator The user that created the delegation.
        @param delegated The user that benefits of the delegation.
    */
    event DelegationAdded(uint indexed poolId, address indexed delegator, address indexed delegated);
}
