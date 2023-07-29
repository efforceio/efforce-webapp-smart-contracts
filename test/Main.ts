import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Main, Token } from "../typechain-types";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("Main", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
        main: Main,
        token: Token,
        decimals: number;

    const
        metadataURI = "uri.metadata",
        contractMetadataURI = "contract.metadata.uri",
        royaltyBps = 10_00;

    before("Initialization", async function() {
        [owner, account1, account2] = (await ethers.getSigners());

        const Utils = await ethers.getContractFactory("Utils");
        const utils = await Utils.deploy();

        const Main = await ethers.getContractFactory(
            "Main",
            {
                libraries: {
                    Utils: utils.address
                }
            }
        );
        main = await Main.deploy(owner.address, metadataURI, contractMetadataURI, royaltyBps);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");

        decimals = await token.decimals();
    });

    describe("Roles", () => {
        it("Sets admin", async () => {
            await expect(main.setAdmin(account1.address, true))
                .emit(main, "RoleAssignment")
                .withArgs(
                    account1.address,
                    0,
                    false
                );

            expect(await main.isAdmin(account1.address)).is.true;
            expect(await main.isAdmin(account2.address)).is.false;

            await expect(main.connect(account1).setAdmin(account2.address, true)).reverted;
            await expect(main.connect(account2).setAdmin(account2.address, true)).reverted;

            await expect(main.setAdmin(account1.address, false))
                .emit(main, "RoleAssignment")
                .withArgs(
                    account1.address,
                    0,
                    true
                );

            expect(await main.isAdmin(account1.address)).is.false;

            // account1 is admin.
            await main.setAdmin(account1.address, true);
        });

        it("Sets manager", async () => {
            await expect(main.setManager(account1.address, true))
                .emit(main, "RoleAssignment")
                .withArgs(
                    account1.address,
                    1,
                    false
                );

            expect(await main.isManager(account1.address)).is.true;
            expect(await main.isManager(account2.address)).is.false;

            await expect(main.connect(account1).setManager(account2.address, true)).reverted;
            await expect(main.connect(account2).setManager(account2.address, true)).reverted;

            await expect(main.setManager(account1.address, false))
                .emit(main, "RoleAssignment")
                .withArgs(
                    account1.address,
                    1,
                    true
                );

            expect(await main.isManager(account1.address)).is.false;

            // account2 is manager.
            await main.setManager(account2.address, true);
        });

        it("Sets owner", async () => {
            expect(await main.owner()).equal(owner.address);

            await expect(main.connect(account1).setOwner(account1.address)).reverted;
            await expect(main.connect(account2).setOwner(account2.address)).reverted;

            await expect(main.setOwner(account1.address))
                .emit(main, "RoleAssignment")
                .withArgs(
                    account1.address,
                    2,
                    false
                );

            expect(await main.owner()).equal(account1.address);

            await main.connect(account1).setOwner(owner.address);
        });
    });

    describe("Accounts", () => {
        it("Updates account", async () => {
            await expect(main.connect(account2).updateAccount(account2.address, true)).reverted;

            await expect(main.connect(account1).updateAccount(account1.address, true))
                .emit(main, "AccountEnabled")
                .withArgs(
                    account1.address,
                    true
                );

            expect(await main.isAccountEnabled(account1.address)).is.true;
            expect(await main.isAccountEnabled(account2.address)).is.false;

            await expect(main.updateAccount(account1.address, false))
                .emit(main, "AccountEnabled")
                .withArgs(
                    account1.address,
                    false
                );

            expect(await main.isAccountEnabled(account1.address)).is.false;

            // account1 and account 2 are enabled.
            await main.updateAccount(account1.address, true);
            await main.updateAccount(account2.address, true);
        });
    });

    describe("Contract metadata", () => {
       it("Sets contract uri", async () => {
           const newUri = "uri2";

           expect(await main.contractURI()).equal(contractMetadataURI);

           await expect(main.connect(account1).setContractURI(newUri)).reverted;
           await expect(main.connect(account2).setContractURI(newUri)).reverted;

           await expect(main.setContractURI(newUri))
               .emit(main, "ContractURIUpdated")
               .withArgs(newUri);

           expect(await main.contractURI()).equal(newUri);

           main.setContractURI(contractMetadataURI);
       });
    });

    describe("Royalties", () => {
        it("Sets royalties", async () => {
            const price = 100;
            const royalty1 = 10;
            const newBps = 20_00;
            const royalty2 = 20;

            expect(await main.royaltyInfo(0, price)).deep.equal([main.address, royalty1]);

            await expect(main.setRoyaltyInfo(newBps))
                .emit(main, "RoyaltiesUpdated")
                .withArgs(newBps);

            expect(await main.royaltyInfo(0, price)).deep.equal([main.address, royalty2]);

            await main.setRoyaltyInfo(royaltyBps);
        });
    });

    describe("ERC-165", () => {
        it("ERC-165", async function() {
            expect(await main.supportsInterface("0x01ffc9a7")).to.true;
        });
        it("ERC-1155", async function() {
            expect(await main.supportsInterface("0xd9b67a26")).to.true;
        });
        it("ERC-1155 metadata", async function() {
            expect(await main.supportsInterface("0x0e89341c")).to.true;
        });
        it("ERC-5006", async function() {
            expect(await main.supportsInterface("0xc26d96cc")).to.true;
        });
        it("ERC-2981", async function() {
            expect(await main.supportsInterface("0x2a55205a")).to.true;
        });
    });

    describe("Bank", () => {

    });

});
