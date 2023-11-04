import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Pools, Roles, Token } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";
import { time } from '@nomicfoundation/hardhat-network-helpers';

describe("Pools test", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
        pools: Pools,
        roles: Roles,
        nPools = 0,
        token: Token;
    const
        lockingPeriod = 1;

    before("Initialization", async function() {
        [owner, account1, account2] = await ethers.getSigners();

        const Roles = await ethers.getContractFactory("Roles");
        roles = await Roles.deploy(owner.address);

        await roles.setAdmin(account1.address, true);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");

        const Pools = await ethers.getContractFactory("Pools");
        pools = await Pools.deploy(roles.address, token.address);
    });

    describe("Create pool", () => {
        it("Fails if sender is not admin or owner", async () => {
            await expect(pools.connect(account2).createPool(lockingPeriod)).reverted;
        });
        it("Executes if sender is admin or owner", async () => {
            await expect(pools.connect(account1).createPool(lockingPeriod)).not.reverted;
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

            const timestamp = await time.latest();
            const poolItem = await pools.getPool(nPools-1);

            expect(poolItem.createdAt).equal(timestamp);
            expect(poolItem.stakingStartedAt).equal(0);
            expect(poolItem.allocated).equal(0);
            expect(poolItem.canceled).equal(false);
        });
    });

    describe("Stacking, unstaking, and cancel", () => {
        it("Stacks funds", async () => {
            await token.mintTo(account2.address, 100);
            token.connect(account2).approve(pools.address, 100);

            await expect(pools.connect(account2).stake(0, 50))
                .emit(pools, "Staking").withArgs(
                    account2.address,
                    account2.address,
                    0,
                    50,
                    true
                );
            await expect(pools.connect(account2).stake(0, 50)).not.reverted;
            await expect(pools.connect(account2).stake(0, 50)).reverted;

            expect(await pools.getStakedAmountForAccount(0, account2.address)).equal(100);
            expect(await pools.getStakedAmount(0)).equal(100);
            expect(await token.balanceOf(pools.address)).equal(100);
        });
        it("Stacks funds for", async () => {
            await expect(pools.connect(account2).stakingFor(0, 50, account2.address)).reverted;
            await expect(pools.stakingFor(0, 50, account1.address))
                .emit(pools, "Staking").withArgs(
                    account1.address,
                    owner.address,
                    0,
                    50,
                    true
                );

            expect(await pools.getStakedAmountForAccount(0, account1.address)).equal(50);
            expect(await pools.getStakedAmount(0)).equal(150);
        });
        it("Cannot unstack during pool funding", async () => {
            await expect(pools.connect(account2).unstake(0)).reverted;
        });
        it("Starts staking period", async () => {
            await expect(pools.connect(account2).startStakingPeriod(0)).reverted;
            await expect(pools.connect(account1).startStakingPeriod(1))
                .emit(pools, "PoolChangedState").withArgs(1, 0, 0);
            await expect(pools.startStakingPeriod(0)).not.reverted;

            const timestamp = await time.latest();
            const pool = await pools.getPool(0);

            expect(pool.stakingStartedAt).equal(timestamp);

            await expect(pools.connect(account2).stake(0, 0)).reverted;
            await expect(pools.connect(account2).unstake(0)).reverted;

            setTimeout(() => null, 1000);

            await expect(pools.connect(account2).stake(0, 0)).reverted;
            await expect(pools.connect(account2).unstake(0)).reverted;
        });
        it("Allocates funds", async () => {
            await token.mintTo(pools.address, 10000);

            await expect(pools.connect(account2).setDistributionForPool(0, 1000)).reverted;
            await expect(pools.connect(account1).setDistributionForPool(0, 1000))
                .emit(pools, "PoolChangedState").withArgs(0, 2, 1000);
            await expect(pools.setDistributionForPool(0, 1000)).reverted;
        });
        it("Cancels pool", async () => {
            await pools.stakingFor(2, 100, account1.address);

            await expect(pools.connect(account2).cancelPool(2)).reverted;
            await expect(pools.connect(account1).cancelPool(2))
                .emit(pools, "PoolChangedState").withArgs(2, 1, 0);
            await expect(pools.cancelPool(2)).not.reverted;

            const pool = await pools.getPool(2);
            expect(pool.canceled).true;
        });
        it("Unstakes funds", async () => {
            const b1 = Number(await token.balanceOf(account1.address));
            const b2 = Number(await token.balanceOf(account2.address));
            const s1 = Number(await pools.getStakedAmountForAccount(0, account1.address));
            const s2 = Number(await pools.getStakedAmountForAccount(0, account2.address));
            const a = Number((await pools.getPool(0)).allocated);
            const e1 = s1 / (s1 + s2) * a;
            const e2 = s2 / (s1 + s2) * a;

            await expect(pools.connect(account1).unstake(0))
                .emit(pools, "Staking").withArgs(
                    account1.address,
                    account1.address,
                    0,
                    Math.floor(e1),
                    false
                );
            await expect(pools.connect(account2).unstake(0)).not.reverted;

            const b1a = Number(await token.balanceOf(account1.address));
            const b2a = Number(await token.balanceOf(account2.address));

            expect(b1a).equal(Math.floor(e1 + b1));
            expect(b2a).equal(Math.floor(e2 + b2));

            const bb =  Number(await token.balanceOf(account1.address));
            const sc = Number(await pools.getStakedAmountForAccount(2, account1.address));

            await expect(pools.connect(account1).unstake(2)).not.reverted;

            const ba =  Number(await token.balanceOf(account1.address));
            expect(ba).equal(Math.floor(bb + sc));
        });
    });

    describe("Withdraw funds from contract", () => {
        it("Withdraws", async () => {
            const b1 = Number(await token.balanceOf(owner.address));

            await expect(pools.connect(account2).withdraw(1, owner.address)).reverted;
            await expect(pools.connect(account1).withdraw(1, owner.address)).not.reverted;
            await expect(pools.withdraw(1, owner.address)).not.reverted;

            const b2 = Number(await token.balanceOf(owner.address));
            expect(b2-b1).equal(2);
        });
    })
});
