import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Main } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("Main", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
        main: Main;

    const
        metadataURI = "uri.metadata",
        contractMetadataURI = "contract.metadata.uri",
        royaltyBps = 10;

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
    });

    beforeEach("Deploy contract", async () => {

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

    });

});
