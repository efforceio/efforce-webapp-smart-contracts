import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Roles, Bank, Token } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("Bank test", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
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
        bank = await Bank.deploy(token.address, roles.address);

        token.mintTo(bank.address, 100);
    });

    it("Withdraws funds", async () => {
        await expect(bank.connect(account2).withdraw(account2.address, 10)).reverted;

        await expect(bank.withdraw(account2.address, 10))
            .emit(bank, "Withdrawal")
            .withArgs(account2.address, 10);

        expect(await token.balanceOf(bank.address)).equal(90);
    });
});
