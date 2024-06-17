import { Roles, Bank, Token } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("Bank test", () => {
    let
        owner: HardhatEthersSigner,
        account1: HardhatEthersSigner,
        account2: HardhatEthersSigner,
        roles: Roles,
        token: Token,
        bank: Bank;

    before("Initialization", async () => {
        [owner, account1, account2] = await ethers.getSigners();

        const Roles = await ethers.getContractFactory("Roles");
        roles = await Roles.deploy(owner.address);
        await roles.setAdmin(account1.address, true);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");

        const Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy(token.getAddress(), roles.getAddress());

        token.mintTo(bank.getAddress(), 100);
    });

    it("Withdraws funds", async () => {
        await expect(bank.connect(account2).withdraw(account2.address, 10)).reverted;

        await expect(bank.withdraw(account2.address, 10))
            .emit(bank, "Withdrawal")
            .withArgs(account2.address, 10);

        expect(await token.balanceOf(bank.getAddress())).equal(90);
    });
});
