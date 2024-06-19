import { Roles, Bank, Token } from "../typechain-types";
import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("Bank test", () => {
    let
        owner: HardhatEthersSigner,
        account1: HardhatEthersSigner,
        account2: HardhatEthersSigner,
        roles: Roles,
        token: Token,
        tokenAddress: string,
        bank: Bank;

    before("Initialization", async () => {
        [owner, account1, account2] = await ethers.getSigners();

        const Roles = await ethers.getContractFactory("Roles");
        roles = await upgrades.deployProxy(Roles, []) as unknown as Roles;
        await roles.waitForDeployment();
        await roles.initializer(owner.address);
        await roles.setAdmin(account1.address, true);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");
        tokenAddress = await token.getAddress();

        const Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy(token.getAddress(), roles.getAddress());

        await token.mintTo(bank.getAddress(), 100);
    });

    it("Withdraws funds", async () => {
        await expect(bank.connect(account2)['withdraw(address,uint256)'](account2.address, 10)).reverted;

        await expect(bank['withdraw(address,uint256)'](account2.address, 10))
            .emit(bank, "Withdrawal")
            .withArgs(account2.address, 10, tokenAddress);

        expect(await token.balanceOf(bank.getAddress())).equal(90);
    });

    it("Withdraws funds for other tokens", async () => {
        await expect(bank.connect(account2)['withdraw(address,uint256,address)'](
            account2.address,
            10,
            tokenAddress)
        ).reverted;

        await expect(bank['withdraw(address,uint256,address)'](account2.address, 10, tokenAddress))
            .emit(bank, "Withdrawal")
            .withArgs(account2.address, 10, tokenAddress);

        expect(await token.balanceOf(bank.getAddress())).equal(80);
    });
});
