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
    uint public numberOfPools;
    mapping(uint=>Pool) private idToPool;
    mapping(address account => mapping(uint poolId => uint stacked)) private addressToPoolStaking;
    mapping(address account => mapping(uint poolId => bool withdrawn)) private addressToPoolWithdrawn;
    mapping(address account => mapping(uint poolId => bool withdrawn)) private addressToDiscountWithdrawn;
    mapping(uint=>uint) private poolToStaked;
    mapping(uint=>uint) private poolToStakedWithoutFunds;
    mapping (uint poolId => mapping(address account => address delegated)) private poolToDelegation;
    mapping (uint poolId => mapping(address delegated => address delegator)) private poolToDelegator;
    address public lockingContract;

    uint[2] private lockingSteps;
    uint[2] private discounts;
    uint private baseFee;

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

        lockingSteps = [250_000_000_000_000_000_000_000, 500_000_000_000_000_000_000_000];
        discounts = [10, 15];
        baseFee = 20;
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
        @notice Raises an error if the user already withdrawn the reward for the pool.
        @param account The account's address.
        @param poolId The id of the pool.
    */
    modifier canWithdrawDiscount(address account, uint poolId) {
        require(!addressToDiscountWithdrawn[account][poolId], Errors.NOT_ALLOWED);
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
        require(poolToDelegator[poolId][delegated] == address(0), Errors.NOT_ALLOWED);
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
        @notice Will raise an error if the account already withdrawn funds.
    */
    modifier hasNotWithdrawn(uint poolId, address account) {
        require(!addressToPoolWithdrawn[account][poolId], Errors.NOT_ALLOWED);
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
    function stake(uint id, uint amount) external {
        IERC20(tokenAddress).transferFrom(msg.sender, bankContract, amount);
        _stake(id, amount, msg.sender);
    }

    function stakeWithoutFunds(uint id, uint amount)
        adminOrOwner(msg.sender)
        external
    {
        _stake(id, amount, msg.sender);
        poolToStakedWithoutFunds[id] += amount;
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
        emit Staking(account, msg.sender, id, amount);
    }

    /*
        @notice Unstakes funds from the smart contract.
            If the unstake is done after the staking period ended, it will return the staked amount plus interests,
            otherwise it will return the exact amount that was staked.
        @dev Can be called if the pool is canceled, the staking period ended or is not started.
        @dev Raises an error if the user already withdrawn the reward.
        @param id The id of the target pool.
    */
    function unstake(uint256 id)
        external
        isUnstakingPeriod(id, false)
        hasNotWithdrawn(id, msg.sender)
    {
        if (idToPool[id].stakingStartedAt > 0) {
            uint grossDistribution = getGrossDistribution(msg.sender, id);
            uint netDistribution = getNetDistributionForPoolAndAccount(id, msg.sender, grossDistribution);
            IBank(bankContract).withdraw(msg.sender, netDistribution);
            emit Unstaking(msg.sender, id, netDistribution);
        } else {
            uint amount = addressToPoolStaking[msg.sender][id];
            IBank(bankContract).withdraw(msg.sender, amount);
            emit Unstaking(msg.sender, id, amount);
        }
        addressToPoolWithdrawn[msg.sender][id] = true;
    }


    /*
        @notice Withdraw discount rewards for delegations.
        @param poolId The id of the pool.
    */
    function withdrawDelegationRewards(uint poolId)
        external
        isUnstakingPeriod(poolId, true)
        canWithdrawDiscount(msg.sender, poolId)
    {
        Lock memory accountLock = ILocking(lockingContract).getLastLockForAccount(msg.sender);

        require(
            accountLock.startTimestamp <= idToPool[poolId].stakingStartedAt &&
            accountLock.endTimestamp == 0 &&
            poolToDelegator[poolId][msg.sender] == address(0) &&
            poolToDelegation[poolId][msg.sender] != address(0),
            Errors.NOT_ALLOWED
        );

        uint distribution = getGrossDistribution(poolToDelegation[poolId][msg.sender], poolId);
        uint discount = getDiscount(accountLock, distribution, poolId, true);
        addressToDiscountWithdrawn[msg.sender][poolId] = true;

        require(discount > 0, Errors.NO_CONTRIBUTION);

        IBank(bankContract).withdraw(msg.sender, discount);
        emit WithdrawDiscount(msg.sender, poolId, discount);
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
        poolToDelegator[poolId][account] = msg.sender;

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
        if (poolToDelegator[poolId][account] != address(0)) {
            try ILocking(lockingContract).getLastLockForAccount(poolToDelegator[poolId][account]) returns (
                Lock memory delegatorLock
            ) {
                discount = getDiscount(delegatorLock, distribution, poolId, true);
            } catch {}
        }

        // If the account has an active lock, it execute the code in the brackets.
        try ILocking(lockingContract).getLastLockForAccount(account) returns (Lock memory accountLock) {
            // Apply the discount if the account has an active lock and it has no delegations.
            if (
                poolToDelegation[poolId][account] == address(0)
            ) {
                discount = getDiscount(accountLock, distribution, poolId, false);
            }
        } catch {}

        return baseReward + discount;
    }

    function getGrossDistribution(address account, uint poolId) internal view returns(uint) {
        return (
            addressToPoolStaking[account][poolId] * idToPool[poolId].allocated
        ) / poolToStaked[poolId];
    }

    function getDiscount(Lock memory lock, uint grossDistribution, uint poolId, bool isHalf)
        internal
        view
        returns(uint)
    {
        uint discount = 0;
        if (
            lock.startTimestamp <= idToPool[poolId].stakingStartedAt &&
            lock.endTimestamp == 0
        ) {
            if (lock.amount >= lockingSteps[0] && lock.amount < lockingSteps[1]) {
                discount = (grossDistribution * discounts[0] / 100);
            }
            if (lock.amount > lockingSteps[1]) {
                discount = (grossDistribution * discounts[1] / 100);
            }

            if (isHalf) {
                discount /= 2;
            }
        }

        return discount;
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

    function getStakedAmountForPoolWithFunds(uint256 id)
        external
        view
        returns(uint256)
    {
        return poolToStaked[id] - poolToStakedWithoutFunds[id];
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
    */
    event Staking(address indexed account, address sender, uint256 indexed id, uint256 amount);

    /*
        @notice Emitted when an account stakes or unstakes some funds in a pool.
        @param sender The target account.
        @param id The id of the target pool.
        @param amount The amount that is staked or unstaked.
    */
    event Unstaking(address indexed sender, uint256 indexed id, uint256 amount);

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

    /*
        @notice Emitted when a discount is withdrawn.
        @param account The address that will receive the funds.
        @param poolId The id of the pool.
        @param amount The amount that is issued.
    */
    event WithdrawDiscount(address indexed account, uint indexed poolId, uint amount);
}
