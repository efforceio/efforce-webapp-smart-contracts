import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Pools, Roles, Token, Bank } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";
import { time } from '@nomicfoundation/hardhat-network-helpers';

describe("Pools test", () => {
    let
        owner: SignerWithAddress,
        admin: SignerWithAddress,
        user: SignerWithAddress,
        bank: Bank,
        pools: Pools,
        roles: Roles,
        nPools = 0,
        token: Token;
    const
        lockingPeriod = 1,
        stakedAdmin = 2;

    before("Initialization", async function() {
        [owner, admin, user] = await ethers.getSigners();

        const Roles = await ethers.getContractFactory("Roles");
        roles = await Roles.deploy(owner.address);

        await roles.setAdmin(admin.address, true);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");

        const Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy(token.address, roles.address);

        const Pools = await ethers.getContractFactory("Pools");
        pools = await Pools.deploy(roles.address, bank.address);
        await roles.setAdmin(pools.address, true);
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
            token.connect(user).approve(pools.address, stakedAdmin);

            await expect(pools.connect(user).stake(0, stakedAdmin / 2))
                .emit(pools, "Staking").withArgs(
                    user.address,
                    user.address,
                    0,
                    stakedAdmin / 2,
                    true
                );
            await expect(pools.connect(user).stake(0, stakedAdmin / 2)).not.reverted;
            await expect(pools.connect(user).stake(0, stakedAdmin / 2)).reverted;

            expect(await pools.getStakedAmountForAccount(0, user.address)).equal(stakedAdmin);
            expect(await pools.getStakedAmount(0)).equal(stakedAdmin);
            expect(await token.balanceOf(bank.address)).equal(stakedAdmin);
        });
        it("Stacks funds for", async () => {
            await expect(pools.connect(user).stakingFor(0, stakedAdmin / 2, user.address)).reverted;
            await expect(pools.stakingFor(0, stakedAdmin / 2, admin.address))
                .emit(pools, "Staking").withArgs(
                    admin.address,
                    owner.address,
                    0,
                    stakedAdmin / 2,
                    true
                );

            expect(await pools.getStakedAmountForAccount(0, admin.address)).equal(stakedAdmin / 2);
            expect(await pools.getStakedAmount(0)).equal(stakedAdmin + stakedAdmin / 2);
            await token.mintTo(bank.address, stakedAdmin / 2);
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
            await token.mintTo(bank.address, stakedAdmin * 100);

            await expect(pools.connect(user).setDistributionForPool(0, stakedAdmin * 100)).reverted;
            await expect(pools.connect(admin).setDistributionForPool(0, stakedAdmin * 100))
                .emit(pools, "PoolChangedState").withArgs(0, 2, stakedAdmin * 100);
            await expect(pools.setDistributionForPool(0, stakedAdmin * 100)).reverted;
        });
        it("Cancels pool", async () => {
            await pools.stakingFor(2, stakedAdmin, admin.address);

            await expect(pools.connect(user).cancelPool(2)).reverted;
            await expect(pools.connect(admin).cancelPool(2))
                .emit(pools, "PoolChangedState").withArgs(2, 1, 0);
            await expect(pools.cancelPool(2)).not.reverted;

            const pool = await pools.getPool(2);
            expect(pool.canceled).true;
        });
        it("Unstakes funds", async () => {
            const b1 = Number(await token.balanceOf(admin.address));
            const b2 = Number(await token.balanceOf(user.address));
            const s1 = Number(await pools.getStakedAmountForAccount(0, admin.address));
            const s2 = Number(await pools.getStakedAmountForAccount(0, user.address));
            const a = Number((await pools.getPool(0)).allocated);
            const e1 = s1 / (s1 + s2) * a;
            const e2 = s2 / (s1 + s2) * a;

            await expect(pools.connect(admin).unstake(0))
                .emit(pools, "Staking").withArgs(
                    admin.address,
                    admin.address,
                    0,
                    Math.floor(e1),
                    false
                );
            await expect(pools.connect(user).unstake(0)).not.reverted;

            const b1a = Number(await token.balanceOf(admin.address));
            const b2a = Number(await token.balanceOf(user.address));

            expect(b1a).equal(Math.floor(e1 + b1));
            expect(b2a).equal(Math.floor(e2 + b2));

            const bb =  Number(await token.balanceOf(admin.address));
            const sc = Number(await pools.getStakedAmountForAccount(2, admin.address));

            await expect(pools.connect(admin).unstake(2)).not.reverted;

            const ba =  Number(await token.balanceOf(admin.address));
            expect(ba).equal(Math.floor(bb + sc));
        });
    });
});
