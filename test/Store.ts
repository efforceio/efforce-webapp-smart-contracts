/*import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Roles, Bank, Token, Credits, Store } from "../typechain-types";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Store test", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
        roles: Roles,
        token: Token,
        bank: Bank,
        store: Store,
        credits: Credits;
    const
        price = 1,
        amount = 100;

    before("Initialization", async () => {
        [owner, account1, account2] = await ethers.getSigners();

        const Utils = await ethers.getContractFactory("Utils");
        const utils = await Utils.deploy();

        const Roles = await ethers.getContractFactory("Roles");
        roles = await Roles.deploy(owner.address);
        await roles.setAdmin(account1.address, true);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");

        const Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy(token.address, roles.address);

        const Credits = await ethers.getContractFactory(
            "Credits",
            {
                libraries: {
                    Utils: utils.address
                }
            }
        );
        credits = await Credits.deploy("", roles.address, "", 10_00, bank.address);

        const Store = await ethers.getContractFactory("Store");
        store = await Store.deploy(credits.address, bank.address, roles.address);

        await roles.setAdmin(store.address, true);

        await token.mintTo(owner.address, price * amount);
        await token.mintTo(account1.address, price * amount);
        await token.mintTo(account2.address, price * amount);

        await token.approve(credits.address, price * amount);
        await token.connect(account1).approve(store.address, price * amount);
        await token.connect(account2).approve(store.address, price * amount);

        await credits.updateAccount(account1.address, true);
        await credits.updateAccount(account2.address, true);

        await credits.createProject();
        await credits.setContractOperator(store.address, true);
    });

    it("Buys credits", async () => {
        await credits.openVintage(0, amount, price);
        await credits.openVintage(1, amount, price);

        await expect(store.buyCredits(0, 1)).reverted;
        const credit = await credits.getVintage(0);

        await expect(store.connect(account1).buyCredits(0, 1))
            .emit(store, "CreditsPurchased")
            .withArgs(0, 1, credit.price, account1.address, true, credit.projectId);

        expect((await credits.getVintage(0)).availableCredits).equal(amount - 1);
        expect(await credits.balanceOf(account1.address, 0)).equal(1);

        await expect(store.connect(account2).buyCredits(0, amount)).reverted;
    });

    it("Buys credits for", async () => {
        await expect(store.connect(account2).buyCreditsFor(1, 1, owner.address)).reverted;
        const credit = await credits.getVintage(1);

        await expect(store.buyCreditsFor(1, 1, account1.address))
            .emit(store, "CreditsPurchased")
            .withArgs(1, 1, credit.price, account1.address, false, credit.projectId);

        expect((await credits.getVintage(1)).availableCredits).equal(amount - 1);
        expect(await credits.balanceOf(account1.address, 1)).equal(1);

        await expect(store.connect(account2).buyCreditsFor(1, amount, account1.address)).reverted;
    });

    it("Buys and close vintage", async () => {
        const credit = await credits.getVintage(1);

        await expect(store.connect(account1).buyCredits(1, amount - 1))
            .emit(store, "CreditsPurchased")
            .withArgs(1, amount - 1, credit.price, account1.address, true, credit.projectId)
            .emit(credits, "VintageAction")
            .withArgs(1, 1);
        expect((await credits.getVintage(1)).state).equal(1);
    });

    it("Refunds credits", async () => {
        await credits.openVintage(0, 100, 1);
        await store.connect(account2).buyCredits(2, 1);
        await credits.updateVintageState(2, 2);

        await expect(credits.safeTransferFrom(account2.address, account1.address, 2, 1, [])).reverted;

        const credit = await credits.getVintage(2);

        await expect(store.connect(account2).refundCredits(2))
            .emit(store, "RefundOrRedeem")
            .withArgs(account2.address, 2, credit.projectId)
            .emit(token, "Transfer")
            .withArgs(bank.address, account2.address, 1);

        expect(await token.balanceOf(account2.address)).equal(price * amount);
        expect(await credits.balanceOf(account2.address, 2)).equal(0);
    });
});*/
