import { Pools, Roles, Token, Bank, Locking } from "../typechain-types";
import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("Pools test", () => {
    let
        owner: HardhatEthersSigner,
        admin: HardhatEthersSigner,
        user: HardhatEthersSigner,
        bank: Bank,
        bankAddress: string,
        pools: Pools,
        poolsAddress: string,
        roles: Roles,
        rolesAddress: string,
        nPools = 0,
        poolsUpgraded: Pools,
        token: Token,
        tokenAddress: string,
        locking: Locking,
        lockingAddress: string;
    const
        lockingPeriod = 1,
        stakedAdmin = 2,
        efforceFee = 20;

    before("Initialization", async function() {
        [owner, admin, user] = await ethers.getSigners();

        const Roles = await ethers.getContractFactory("Roles");
        roles = await upgrades.deployProxy(Roles,  []) as unknown as Roles;
        await roles.initializer(owner.address);
        rolesAddress = await roles.getAddress();

        await roles.setAdmin(admin.address, true);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");
        tokenAddress = await token.getAddress();

        const Bank = await ethers.getContractFactory("Bank");
        bank = await upgrades.deployProxy(Bank, []) as unknown as Bank;
        await bank.waitForDeployment();
        await bank.initializer(tokenAddress, rolesAddress);
        bankAddress = await bank.getAddress();

        const Locking = await ethers.getContractFactory("Locking");
        locking = await upgrades.deployProxy(Locking, []) as unknown as Locking;
        await locking.waitForDeployment();
        lockingAddress = await locking.getAddress();

        await locking.initializer(bankAddress, tokenAddress);

        const Pools = await ethers.getContractFactory("Pools");
        pools = await upgrades.deployProxy(Pools, []) as unknown as Pools;
        await pools.waitForDeployment();
        poolsAddress = await pools.getAddress();

        await pools.initializer(rolesAddress, bankAddress, lockingAddress);
        await roles.setAdmin(poolsAddress, true);
    });

    describe("Create pool", () => {
        it("Fails if sender is not admin or owner", async () => {
            await expect(pools.connect(user).createPool(lockingPeriod)).reverted;
        });
        it("Executes if sender is admin or owner", async () => {
            await expect(pools.connect(admin).createPool(lockingPeriod)).not.reverted;
            nPools++;
            await expect(pools.createPool(lockingPeriod)).not.reverted;
            nPools++;
            expect(await pools.numberOfPools()).equal(nPools);
        });
        it("Checks pool details and event", async () => {

            await expect(pools.createPool(lockingPeriod)).emit(
                pools,
                "PoolCreated"
            ).withArgs(nPools, lockingPeriod);
            nPools++;

            const poolItem = await pools.getPool(nPools-1);

            expect(poolItem.stakingStartedAt).equal(0);
            expect(poolItem.allocated).equal(0);
            expect(poolItem.canceled).equal(false);
        });
    });

    describe("Stacking, unstaking, and cancel", () => {
        it("Stacks funds", async () => {
            await token.mintTo(user.address, stakedAdmin);
            token.connect(user).approve(poolsAddress, stakedAdmin);

            await expect(pools.connect(user).stake(0, stakedAdmin / 2))
                .emit(pools, "Staking").withArgs(
                    user.address,
                    user.address,
                    0,
                    stakedAdmin / 2
                );
            await expect(pools.connect(user).stake(0, stakedAdmin / 2)).not.reverted;
            await expect(pools.connect(user).stake(0, stakedAdmin / 2)).reverted;

            expect(await pools.getStakedAmountForPoolAndAccount(0, user.address)).equal(stakedAdmin);
            expect(await pools.getStakedAmountForPool(0)).equal(stakedAdmin);
            expect(await token.balanceOf(bankAddress)).equal(stakedAdmin);
        });
        it("Stacks funds for", async () => {
            await expect(pools.connect(user).stakeFor(0, stakedAdmin / 2, user.address)).reverted;
            await expect(pools.stakeFor(0, stakedAdmin / 2, admin.address))
                .emit(pools, "Staking").withArgs(
                    admin.address,
                    owner.address,
                    0,
                    stakedAdmin / 2
                );

            expect(await pools.getStakedAmountForPoolAndAccount(0, admin.address)).equal(stakedAdmin / 2);
            expect(await pools.getStakedAmountForPool(0)).equal(stakedAdmin + stakedAdmin / 2);
            await token.mintTo(bankAddress, stakedAdmin / 2);
        });
        it("Cannot unstack during pool funding", async () => {
            await expect(pools.connect(user).unstake(0)).reverted;
        });
        it("Starts staking period", async () => {
            await expect(pools.connect(user).startStakingPeriod(0)).reverted;
            await expect(pools.connect(admin).startStakingPeriod(1))
                .emit(pools, "PoolChangedState").withArgs(1, 0, 0);
            await expect(pools.startStakingPeriod(0)).not.reverted;

            const timestamp = await time.latest();
            const pool = await pools.getPool(0);

            expect(pool.stakingStartedAt).equal(timestamp);

            await expect(pools.connect(user).stake(0, 0)).reverted;
            await expect(pools.connect(user).unstake(0)).reverted;

            setTimeout(() => null, lockingPeriod * 1000);

            await expect(pools.connect(user).stake(0, 0)).reverted;
            await expect(pools.connect(user).unstake(0)).reverted;
        });
        it("Allocates funds", async () => {
            await token.mintTo(bankAddress, stakedAdmin * 100);

            await expect(pools.connect(user).setDistributionForPool(0, stakedAdmin * 100)).reverted;
            await expect(pools.connect(admin).setDistributionForPool(0, stakedAdmin * 100))
                .emit(pools, "PoolChangedState").withArgs(0, 2, stakedAdmin * 100);
            await expect(pools.setDistributionForPool(0, stakedAdmin * 100)).reverted;
        });
        it("Cancels pool", async () => {
            await pools.stakeFor(2, stakedAdmin, admin.address);

            await expect(pools.connect(user).cancelPool(2)).reverted;
            await expect(pools.connect(admin).cancelPool(2))
                .emit(pools, "PoolChangedState").withArgs(2, 1, 0);
            await expect(pools.cancelPool(2)).not.reverted;

            const pool = await pools.getPool(2);
            expect(pool.canceled).true;
        });
        it("Unstack funds", async () => {
            // initial balances
            const balance1Start = await token.balanceOf(admin.address);
            const balance2Start = await token.balanceOf(user.address);

            // stacked
            const stacked1 = await pools.getStakedAmountForPoolAndAccount(0, admin.address);
            const stacked2 = await pools.getStakedAmountForPoolAndAccount(0, user.address);

            // total allocation for pool (gross)
            const allocatedGross = (await pools.getPool(0)).allocated;

            // expected rewards
            const feePerc = BigInt(100) - BigInt(efforceFee);
            const reward1 = stacked1 * allocatedGross / (stacked1 + stacked2) * feePerc / BigInt(100);
            const reward2 = stacked2 * allocatedGross / (stacked1 + stacked2) * feePerc / BigInt(100);

            await expect(pools.connect(admin).unstake(0))
                .emit(pools, "Unstaking").withArgs(
                    admin.address,
                    0,
                    reward1,
                );
            await expect(pools.connect(user).unstake(0)).not.reverted;

            const balance1End = await token.balanceOf(admin.address);
            const balance2End = await token.balanceOf(user.address);

            expect(balance1End).equal(reward1 + balance1Start);
            expect(balance2End).equal(reward2 + balance2Start);

            const balanceAdminStart =  Number(await token.balanceOf(admin.address));
            const stackedAdmin = Number(await pools.getStakedAmountForPoolAndAccount(2, admin.address));

            await expect(pools.connect(admin).unstake(2)).not.reverted;

            const balanceAdminEnd =  Number(await token.balanceOf(admin.address));
            expect(balanceAdminEnd).equal(Math.floor(balanceAdminStart + stackedAdmin));
        });
    });

    describe("Upgrades", () => {

        it("Smart contract can be upgraded", async () => {
            const nPoolsBeforeUpgrade = await pools.numberOfPools();

            const Pools = await ethers.getContractFactory("Pools");
            poolsUpgraded = await upgrades.upgradeProxy(poolsAddress, Pools) as unknown as Pools;
            const poolsUpgradedAddress = await poolsUpgraded.getAddress();

            const nPoolsAfterUpgrade = await pools.numberOfPools();

            expect(nPoolsAfterUpgrade).to.equal(nPoolsBeforeUpgrade);
            expect(poolsAddress).to.equal(poolsUpgradedAddress);
        });
        it("Cannot call init function after upgrade", async () => {
            await expect(poolsUpgraded.initializer(rolesAddress, bankAddress, lockingAddress)).reverted;
        });
    });
});
