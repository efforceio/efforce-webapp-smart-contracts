import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, upgrades } from "hardhat";
import { Bank, Locking, Roles, Token } from "../typechain-types";
import { expect } from "chai";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Locking tests", () => {
    let
        owner: HardhatEthersSigner,
        user: HardhatEthersSigner,
        locking: Locking,
        lockingAddress: string,
        token: Token,
        bank: Bank,
        bankAddress: string,
        roles: Roles;

    const amount = 100;

    before('Create wallets', async () => {
        [owner, user] = await ethers.getSigners();
    });

    before('Create complementary contracts', async () => {
        const Roles = await ethers.getContractFactory("Roles");
        roles = await Roles.deploy(owner.address);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");

        const Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy(token.getAddress(), roles.getAddress());
        bankAddress = await bank.getAddress();
    });

    beforeEach('Initialization', async () => {
        const Locking = await ethers.getContractFactory("Locking");
        locking = await upgrades.deployProxy(Locking, []) as unknown as Locking;
        await locking.waitForDeployment();
        lockingAddress = await locking.getAddress();

        await locking.initializer(bankAddress);
        await roles.setAdmin(lockingAddress, true);
    });

    beforeEach('Allocate funds', async () => {
        await token.mintTo(user.address, amount);
        await token.connect(user).approve(lockingAddress, amount);
    });

    describe('Lock funds', () => {
        it('Locks funds', async () => {
            const res = expect(locking.connect(user).lock(amount));
            const timestamp = await time.latest();

            await res
                .emit(locking, 'FundsLocked')
                .withArgs(1, user.address, amount);

            let lockingStruct = await locking.getLastLockForAccount(user.address);
            expect(lockingStruct.amount).equal(amount);
            expect(lockingStruct.startTimestamp).equal(timestamp);
            expect(lockingStruct.endTimestamp).equal(0);

            lockingStruct = await locking.getLock(1);
            expect(lockingStruct.amount).equal(amount);
            expect(lockingStruct.startTimestamp).equal(timestamp);
            expect(lockingStruct.endTimestamp).equal(0);
        });

        it('Give errors when getting non existing lock', async () => {
            await expect(locking.getLock(0)).revertedWith("500");
            await expect(locking.getLock(1)).revertedWith("500");

            await expect(locking.getLastLockForAccount(owner)).revertedWith("500");
        });
    });

    describe('Unlock funds', () => {
        beforeEach('Lock funds', async () => {
            await locking.connect(user).lock(amount);
        });

        it('Unlocks funds', async () => {
            const previousBalance = await token.balanceOf(user.address);

            await expect(locking.connect(user).unlock())
                .emit(locking, 'FundsUnlocked')
                .withArgs(1, user.address);

            expect ( await token.balanceOf(user.address)).equal(previousBalance + BigInt(amount));
        });

        it('Cannot unlocks twice', async () => {
            locking.connect(user).unlock();
            await expect(locking.connect(user).unlock()).revertedWith("900");
        });

        it('Cannot unlock for non existing locks', async () => {
            await expect(locking.unlock()).revertedWith("500");
        });
    });
});
