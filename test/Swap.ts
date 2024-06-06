/*import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Roles, Bank, Swap, Token, Credits } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("Swap test", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
        roles: Roles,
        token: Token,
        swap: Swap,
        credits: Credits,
        bank: Bank;

    const royaltyBps = 10_00;

    before("Initialization", async () => {
        [owner, account1, account2] = await ethers.getSigners();

        const Roles = await ethers.getContractFactory("Roles");
        roles = await Roles.deploy(owner.address);
        await roles.setAdmin(account1.address, true);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");

        const Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy(token.address, roles.address);

        const Utils = await ethers.getContractFactory("Utils");
        const utils = await Utils.deploy();

        const Credits = await ethers.getContractFactory(
            "Credits",
            {
                libraries: {
                    Utils: utils.address
                }
            }
        );
        credits = await Credits.deploy("", roles.address, "", royaltyBps, bank.address);

        await credits.updateAccount(account1.address, true);
        await credits.updateAccount(account2.address, true);
        await credits.createProject();
        await credits.openVintage(0, 0, 0);
        await credits.updateVintageState(0, 1);
        await credits.safeMint(account1.address, 0, 100, []);
        await token.mintTo(account2.address, 100);

        const Swap = await ethers.getContractFactory("Swap");
        swap = await Swap.deploy(credits.address, bank.address);

        await credits.updateAccount(swap.address, true);
        await roles.setAdmin(swap.address, true);
        await credits.setContractOperator(swap.address, true);
    });

    describe("Listings", async () => {
        it("Creates listing", async () => {
            await expect(swap.connect(account2).createListing(0, 1, 1)).reverted;

            await expect(swap.connect(account1).createListing(0, 1, 100))
                .emit(swap, "CreateListing")
                .withArgs(account1.address, 0, 1, 100)
                .emit(credits, "TransferSingle")
                .withArgs(swap.address, account1.address, swap.address, 0, 100);
        });

        it("Buys from listing", async () => {
            await token.connect(account2).approve(swap.address, 100);
            await expect(swap.connect(account1).buyFromListing(0, 1)).reverted;

            await credits.connect(account1).setApprovalForAll(swap.address, true);

            await expect(swap.connect(account2).buyFromListing(0, 1))
                .emit(swap, "Purchase")
                .withArgs(0, account1.address, account2.address, 1, 1)
                .emit(swap, "ListingUpdated")
                .withArgs(0, 99, 1)
                .emit(token, "Transfer")
                .withArgs(account2.address, account1.address, 1)
                .emit(token, "Transfer")
                .withArgs(account2.address, bank.address, 0);

            await expect(swap.connect(account2).buyFromListing(0, 99))
                .emit(swap, "Purchase")
                .withArgs(0, account1.address, account2.address, 99, 99)
                .emit(swap, "ListingUpdated")
                .withArgs(0, 0, 1)
                .emit(token, "Transfer")
                .withArgs(account2.address, account1.address, 90)
                .emit(token, "Transfer")
                .withArgs(account2.address, bank.address, 9)
                .emit(swap, "ListingClosed")
                .withArgs(0, true);

            expect(await credits.balanceOf(account2.address, 0)).equal(100);
            expect(await token.balanceOf(account1.address)).equal(91);
        });
        it("Updates listing", async () => {
            await credits.openVintage(0, 0, 0);
            await credits.safeMint(account1.address, 1, 100, []);
            await credits.updateVintageState(1, 1);
            await swap.connect(account1).createListing(1, 1, 100);

            await expect(swap.connect(account2).updateListing(1, 2, 90)).reverted;

            await expect(swap.connect(account1).updateListing(1, 2, 90))
                .emit(swap, "ListingUpdated")
                .withArgs(1, 90, 2)
                .emit(credits, "TransferSingle")
                .withArgs(swap.address, swap.address, account1.address, 1, 10);

            let listing = await swap.getListing(1);
            expect(listing.quantity).equal(90);
            expect(listing.pricePerToken).equal(2);

            await expect(swap.connect(account1).updateListing(1, 1, 100))
                .emit(swap, "ListingUpdated")
                .withArgs(1, 100, 1)
                .emit(credits, "TransferSingle")
                .withArgs(swap.address, account1.address, swap.address, 1, 10);

            listing = await swap.getListing(1);
            expect(listing.quantity).equal(100);
            expect(listing.pricePerToken).equal(1);
        });
        it("Closes listing", async () => {
            await expect(swap.connect(account2).closeListing(1)).reverted;

            await expect(swap.connect(account1).closeListing(1))
                .emit(swap, "ListingClosed")
                .withArgs(1, false)
                .emit(credits, "TransferSingle")
                .withArgs(swap.address, swap.address, account1.address, 1, 100);

            await token.mintTo(account2.address, 2);
            await expect(swap.connect(account2).buyFromListing(1, 1)).reverted;

            expect(await credits.balanceOf(account1.address, 1)).equal(100);
        });
        it("Buy from multiple listings", async () => {
            await swap.connect(account1).createListing(1, 1, 1);
            await swap.connect(account1).createListing(1, 1, 1);

            await token.mintTo(account2.address, 2);
            await token.connect(account2).approve(swap.address, 2);

            await expect(swap.connect(account2).buyFromListingBatch([2, 3], [1, 1]))
                .emit(swap, "Purchase")
                .withArgs(1, account1.address, account2.address, 1, 1)
                .emit(swap, "Purchase")
                .withArgs(1, account1.address, account2.address, 1, 1)
                .emit(swap, "ListingUpdated")
                .withArgs(2, 0, 1)
                .emit(swap, "ListingUpdated")
                .withArgs(3, 0, 1)
                .emit(token, "Transfer")
                .withArgs(account2.address, account1.address, 1)
                .emit(token, "Transfer")
                .withArgs(account2.address, account1.address, 1)
                .emit(token, "Transfer")
                .withArgs(account2.address, bank.address, 0)
                .emit(token, "Transfer")
                .withArgs(account2.address, bank.address, 0)
                .emit(swap, "ListingClosed")
                .withArgs(2, true)
                .emit(swap, "ListingClosed")
                .withArgs(3, true);
        });
    });

    describe("Offers", () => {
        before("Refils token", async () => {
            await token.mintTo(account1.address, 9);
        });
        it("Creates offer", async () => {
            await expect(swap.connect(account1).makeOffer(0, 1, 100)).reverted;

            await token.connect(account1).approve(swap.address, 100);
            await expect(swap.connect(account1).makeOffer(0, 1, 100))
                .emit(swap, "OfferCreated")
                .withArgs(0, 1, 100, account1.address);

            expect(await token.balanceOf(bank.address)).equal(109);
        });
        it("Accepts offer", async () => {
            await expect(swap.connect(account1).acceptOffer(0, 1)).reverted;

            await expect(swap.connect(account2).acceptOffer(0, 1))
                .emit(swap, "Purchase")
                .withArgs(0, account2.address, account1.address, 1, 1)
                .emit(swap, "OfferUpdated")
                .withArgs(0, 1, 99)
                .emit(token, "Transfer")
                .withArgs(bank.address, account2.address, 1)
                .emit(token, "Transfer")
                .withArgs(bank.address, bank.address, 0);

            await expect(swap.connect(account2).acceptOffer(0, 99))
                .emit(swap, "Purchase")
                .withArgs(0, account2.address, account1.address, 99, 99)
                .emit(swap, "OfferUpdated")
                .withArgs(0, 1, 0)
                .emit(token, "Transfer")
                .withArgs(bank.address, account2.address, 90)
                .emit(token, "Transfer")
                .withArgs(bank.address, bank.address, 9)
                .emit(swap, "OfferClosed")
                .withArgs(0, true);
        });
        it("Updates offer", async () => {
            await credits.openVintage(0, 0, 0);
            await credits.safeMint(account1.address, 1, 100, []);
            await token.mintTo(account2.address, 200);
            await token.connect(account2).approve(swap.address, 300);

            await swap.connect(account2).makeOffer(2, 2, 100);

            await expect(swap.connect(account2).updateOffer(1, 1, 50))
                .emit(swap, "OfferUpdated")
                .withArgs(1, 1, 50)
                .emit(token, "Transfer")
                .withArgs(bank.address, account2.address, 150);

            await expect(swap.connect(account2).updateOffer(1, 1, 100))
                .emit(swap, "OfferUpdated")
                .withArgs(1, 1, 100)
                .emit(token, "Transfer")
                .withArgs(account2.address, bank.address, 50);
        });
        it("Closes offer", async () => {
            await expect(swap.closeOffer(1)).reverted;

            await expect(swap.connect(account2).closeOffer(1))
                .emit(swap, "OfferClosed")
                .withArgs(1, false)
                .emit(token, "Transfer")
                .withArgs(bank.address, account2.address, 100);

            await token.connect(account1).approve(swap.address, 1);
            await expect(swap.connect(account1).acceptOffer(1, 1)).reverted;
        });
        it("Accepts batch offers", async () => {
            await swap.connect(account2).makeOffer(0, 1, 1);
            await swap.connect(account2).makeOffer(0, 1, 1);
            await token.connect(account1).approve(swap.address, 2);

            await expect(swap.connect(account1).acceptOfferBatch([2, 3], [1, 1]))
                .emit(swap, "Purchase")
                .withArgs(0, account1.address, account2.address, 1, 1)
                .emit(swap, "Purchase")
                .withArgs(0, account1.address, account2.address, 1, 1)
                .emit(swap, "OfferUpdated")
                .withArgs(2, 1, 0)
                .emit(swap, "OfferUpdated")
                .withArgs(3, 1, 0)
                .emit(token, "Transfer")
                .withArgs(bank.address, account1.address, 1)
                .emit(token, "Transfer")
                .withArgs(bank.address, bank.address, 0)
                .emit(swap, "OfferClosed")
                .withArgs(2, true)
                .emit(swap, "OfferClosed")
                .withArgs(3, true);
        });
    });
});
*/
