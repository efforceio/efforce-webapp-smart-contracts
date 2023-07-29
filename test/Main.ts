import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Main, Token } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("Main", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
        main: Main,
        token: Token,
        decimals: number,
        projectIds: number[],
        creditIds: number[];

    const
        metadataURI = "uri.metadata",
        contractMetadataURI = "contract.metadata.uri",
        royaltyBps = 10_00,
        amount = 100;

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

        projectIds = [];
        creditIds = [];
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
        it("Withdraws", async () => {
            await token.mintTo(main.address, 1);

            await expect(main.connect(account1).withdraw(token.address, account1.address, 1)).reverted;
            await expect(main.connect(account2).withdraw(token.address, account2.address, 1)).reverted;

            await expect(main.withdraw(token.address, owner.address, 1))
                .emit(main, "Withdrawal")
                .withArgs(
                    token.address,
                    owner.address,
                    1
                );

            expect(await token.balanceOf(owner.address)).equal(1);
        });
    });

    describe("Projects", () => {
        it("Creates project", async () => {
            await expect(main.connect(account1).createProject()).reverted;

            await expect(main.connect(account2).createProject())
                .emit(main, "ProjectCreation")
                .withArgs(projectIds.length + 1);
            projectIds.push(projectIds.length + 1);

            await expect(main.createProject())
                .emit(main, "ProjectCreation")
                .withArgs(projectIds.length + 1);
            projectIds.push(projectIds.length + 1);
        });

        it("Creates credits for project", async () => {
            const projectId = projectIds[0];

            await expect(main.connect(account1).newCreditsForProject(projectId, amount, account1.address)).reverted;
            await expect(main.connect(account2).newCreditsForProject(0, amount, account1.address)).reverted;
            await expect(main.connect(account2).newCreditsForProject(3, amount, account1.address)).reverted;
            await expect(main.connect(account2).newCreditsForProject(3, amount, owner.address)).reverted;

            expect(await main.newCreditsForProject(projectId, amount, account1.address))
                .emit(main, "NewCreditsReleased")
                .withArgs(
                    creditIds.length + 1,
                    projectId,
                    amount,
                    account1.address
                );
            expect(await main.projectIdForCredit(creditIds.length + 1)).equal(projectId);
            creditIds.push(creditIds.length + 1);

            expect(await main.connect(account2).newCreditsForProject(projectId, amount, account2.address))
                .emit(main, "NewCreditsReleased")
                .withArgs(
                    creditIds.length + 1,
                    projectId,
                    amount,
                    account2.address
                );
            expect(await main.projectIdForCredit(creditIds.length + 1)).equal(projectId);
            creditIds.push(creditIds.length + 1);
        });

        it("projectIdForCredit", async () => {
            await expect(main.projectIdForCredit(0)).reverted;
        });
    });

    describe("ERC-1155", () => {
        it("Transfers credits", async () => {
            await expect(main.connect(account2).safeTransferFrom(
                account1.address,
                account2.address,
                creditIds[0],
                amount,
                "0x00"
            )).reverted;
            await expect(main.connect(account1).safeTransferFrom(
                account1.address,
                owner.address,
                creditIds[0],
                amount,
                "0x00"
            )).reverted;

            await expect(main.connect(account1).safeTransferFrom(
                account1.address,
                account2.address,
                creditIds[0],
                amount,
                "0x00"
            ))
                .emit(main, "TransferSingle")
                .withArgs(
                    account1.address,
                    account1.address,
                    account2.address,
                    creditIds[0],
                    amount
                );

            expect(await main.balanceOf(account2.address, creditIds[0])).equal(amount);
            expect(await main.balanceOf(account1.address, creditIds[0])).equal(0);
        });

        it("Transfers credits batch", async () => {
            await expect(main.connect(account1).safeBatchTransferFrom(
                account2.address,
                account1.address,
                [creditIds[0]],
                [amount],
                "0x00"
            )).reverted;
            await expect(main.connect(account2).safeBatchTransferFrom(
                account2.address,
                owner.address,
                [creditIds[0]],
                [amount],
                "0x00"
            )).reverted;

            await expect(main.connect(account2).safeBatchTransferFrom(
                account2.address,
                account1.address,
                creditIds,
                [amount],
                "0x00"
            )).reverted;

            await expect(main.connect(account2).safeBatchTransferFrom(
                account2.address,
                account1.address,
                creditIds,
                [amount, amount],
                "0x00"
            )).
                emit(main, "TransferBatch")
                .withArgs(
                    account2.address,
                    account2.address,
                    account1.address,
                    creditIds,
                    [amount, amount]
                );

            expect(await main.balanceOf(account1.address, creditIds[0])).equal(amount);
            expect(await main.balanceOf(account1.address, creditIds[1])).equal(amount);
            expect(await main.balanceOf(account2.address, creditIds[0])).equal(0);
            expect(await main.balanceOf(account2.address, creditIds[1])).equal(0);

            await main.connect(account1).safeTransferFrom(
                account1.address,
                account2.address,
                creditIds[1],
                amount,
                "0x00"
            );
        });

        it("Sets approval for all", async () => {
            await expect(main.connect(account1).setApprovalForAll(owner.address, true)).reverted;

            await expect(main.connect(account1).setApprovalForAll(account2.address, true))
                .emit(main, "ApprovalForAll")
                .withArgs(
                    account1.address,
                    account2.address,
                    true
                );

            await expect(main.connect(account2).safeTransferFrom(
                account1.address,
                account2.address,
                creditIds[0],
                amount,
                "0x00"
            )).not.reverted;

            await main.connect(account2).safeTransferFrom(
                account2.address,
                account1.address,
                creditIds[0],
                amount,
                "0x00"
            );
        });

        it("Updates metadata uri", async () => {
            const newUri = "uri2";

            await expect(main.connect(account1).updateMetadataUri(newUri)).reverted;
            await expect(main.connect(account2).updateMetadataUri(newUri)).reverted;

            await expect(main.updateMetadataUri(newUri))
                .emit(main, "MetadataUriUpdated")
                .withArgs(
                    newUri
                );

            expect(await main.uri(1)).equal(newUri);
        });

        it("Gets uri", async () => {
            await expect(main.uri(0)).reverted;
        });

        it("Gets balance of", async () => {
            expect(await main.balanceOf(owner.address, 0)).equal(0);
        });

        it("Gets balance of batch", async () => {
            await expect(main.balanceOfBatch([owner.address], [0, 1])).reverted;
            expect(await main.balanceOfBatch([owner.address, account1.address], [0, 1])).deep.equal([0, amount]);
        });

        it("Gets approved for all", async () => {
            expect(await main.isApprovedForAll(account1.address, account2.address)).is.true;
            expect(await main.isApprovedForAll(account2.address, account1.address)).is.false;
        });
    });

});
