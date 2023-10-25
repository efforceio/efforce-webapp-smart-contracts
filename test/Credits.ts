import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Credits, Token } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("Credits test", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
        credits: Credits,
        token: Token,
        projectIds: number[],
        creditIds: number[],
        recordIds: number[],
        phaseIds: number[],
        lastDate: Date;

    const
        metadataURI = "uri.metadata",
        contractMetadataURI = "contract.metadata.uri",
        royaltyBps = 10_00,
        amount = 100,
        price = 1,
        days = 1;

    before("Initialization", async function() {
        [owner, account1, account2] = (await ethers.getSigners());

        const Utils = await ethers.getContractFactory("Utils");
        const utils = await Utils.deploy();

        const Roles = await ethers.getContractFactory("Roles");
        const roles = await Roles.deploy(owner.address);
        await roles.setAdmin(account1.address, true);

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN");

        const Credits = await ethers.getContractFactory(
            "Credits",
            {
                libraries: {
                    Utils: utils.address
                }
            }
        );
        credits = await Credits.deploy(metadataURI, roles.address, contractMetadataURI, royaltyBps, token.address);

        projectIds = [];
        creditIds = [];
        recordIds = [];
        phaseIds = [];
        lastDate = new Date();
    });

    describe("Accounts", () => {
        it("Updates account", async () => {
            await expect(credits.connect(account2).updateAccount(account2.address, true)).reverted;

            await expect(credits.connect(account1).updateAccount(account1.address, true))
                .emit(credits, "AccountEnabled")
                .withArgs(
                    account1.address,
                    true
                );

            expect(await credits.isAccountEnabled(account1.address)).is.true;
            expect(await credits.isAccountEnabled(account2.address)).is.false;

            await expect(credits.updateAccount(account1.address, false))
                .emit(credits, "AccountEnabled")
                .withArgs(
                    account1.address,
                    false
                );

            expect(await credits.isAccountEnabled(account1.address)).is.false;

            // account1 and account 2 are enabled.
            await credits.updateAccount(account1.address, true);
            await credits.updateAccount(account2.address, true);
        });
    });

    describe("Contract metadata", () => {
        it("Sets contract uri", async () => {
            const newUri = "uri2";

            expect(await credits.contractURI()).equal(contractMetadataURI);

            await expect(credits.connect(account1).setContractURI(newUri)).not.reverted;
            await expect(credits.connect(account2).setContractURI(newUri)).reverted;

            await expect(credits.setContractURI(newUri))
                .emit(credits, "ContractURIUpdated")
                .withArgs(newUri);

            expect(await credits.contractURI()).equal(newUri);

            credits.setContractURI(contractMetadataURI);
        });
    });

    describe("Royalties", () => {
        it("Sets royalties", async () => {
            const price = 100;
            const royalty1 = 10;
            const newBps = 20_00;
            const royalty2 = 20;

            expect(await credits.royaltyInfo(0, price)).deep.equal([credits.address, royalty1]);

            await expect(credits.connect(account2).setRoyaltyInfo(newBps)).reverted;
            await expect(credits.setRoyaltyInfo(newBps))
                .emit(credits, "RoyaltiesUpdated")
                .withArgs(newBps);
            await expect(credits.connect(account1).setRoyaltyInfo(newBps)).not.reverted;

            expect(await credits.royaltyInfo(0, price)).deep.equal([credits.address, royalty2]);

            await credits.setRoyaltyInfo(royaltyBps);
        });
    });

    describe("ERC-165", () => {
        it("ERC-165", async function() {
            expect(await credits.supportsInterface("0x01ffc9a7")).to.true;
        });
        it("ERC-1155", async function() {
            expect(await credits.supportsInterface("0xd9b67a26")).to.true;
        });
        it("ERC-1155 metadata", async function() {
            expect(await credits.supportsInterface("0x0e89341c")).to.true;
        });
        it("ERC-5006", async function() {
            expect(await credits.supportsInterface("0xc26d96cc")).to.true;
        });
        it("ERC-2981", async function() {
            expect(await credits.supportsInterface("0x2a55205a")).to.true;
        });
    });

    describe("Bank", () => {
        it("Withdraws", async () => {
            await token.mintTo(credits.address, 1);

            await expect(credits.connect(account2).withdraw(account2.address, 1)).reverted;

            await expect(credits.withdraw(owner.address, 1))
                .emit(credits, "Withdrawal")
                .withArgs(
                    owner.address,
                    1
                );

            expect(await token.balanceOf(owner.address)).equal(1);
        });
    });

    describe("Projects", () => {
        it("Creates project", async () => {
            await expect(credits.connect(account2).createProject()).reverted;

            await expect(credits.connect(account1).createProject())
                .emit(credits, "ProjectCreation")
                .withArgs(projectIds.length + 1);
            projectIds.push(projectIds.length + 1);

            await expect(credits.createProject())
                .emit(credits, "ProjectCreation")
                .withArgs(projectIds.length + 1);
            projectIds.push(projectIds.length + 1);
        });

        it("Creates credits for project", async () => {
            const projectId = projectIds[0];

            await expect(credits.connect(account2).newCreditsForProject(0, amount, account1.address)).reverted;
            await expect(credits.connect(account2).newCreditsForProject(3, amount, account1.address)).reverted;
            await expect(credits.connect(account2).newCreditsForProject(3, amount, owner.address)).reverted;

            expect(await credits.newCreditsForProject(projectId, amount, account1.address))
                .emit(credits, "NewCreditsReleased")
                .withArgs(
                    creditIds.length + 1,
                    projectId,
                    amount,
                    account1.address
                );
            expect(await credits.projectIdForCredit(creditIds.length + 1)).equal(projectId);
            creditIds.push(creditIds.length + 1);

            expect(await credits.connect(account1).newCreditsForProject(projectId, amount, account2.address))
                .emit(credits, "NewCreditsReleased")
                .withArgs(
                    creditIds.length + 1,
                    projectId,
                    amount,
                    account2.address
                );
            expect(await credits.projectIdForCredit(creditIds.length + 1)).equal(projectId);
            creditIds.push(creditIds.length + 1);
        });

        it("projectIdForCredit", async () => {
            await expect(credits.projectIdForCredit(0)).reverted;
        });
    });

    describe("ERC-1155", () => {
        it("Transfers credits", async () => {
            await expect(credits.connect(account2).safeTransferFrom(
                account1.address,
                account2.address,
                creditIds[0],
                amount,
                "0x00"
            )).reverted;
            await expect(credits.connect(account1).safeTransferFrom(
                account1.address,
                owner.address,
                creditIds[0],
                amount,
                "0x00"
            )).reverted;

            await expect(credits.connect(account1).safeTransferFrom(
                account1.address,
                account2.address,
                creditIds[0],
                amount,
                "0x00"
            ))
                .emit(credits, "TransferSingle")
                .withArgs(
                    account1.address,
                    account1.address,
                    account2.address,
                    creditIds[0],
                    amount
                );

            expect(await credits.balanceOf(account2.address, creditIds[0])).equal(amount);
            expect(await credits.balanceOf(account1.address, creditIds[0])).equal(0);
        });

        it("Transfers credits batch", async () => {
            await expect(credits.connect(account1).safeBatchTransferFrom(
                account2.address,
                account1.address,
                [creditIds[0]],
                [amount],
                "0x00"
            )).reverted;
            await expect(credits.connect(account2).safeBatchTransferFrom(
                account2.address,
                owner.address,
                [creditIds[0]],
                [amount],
                "0x00"
            )).reverted;

            await expect(credits.connect(account2).safeBatchTransferFrom(
                account2.address,
                account1.address,
                creditIds,
                [amount],
                "0x00"
            )).reverted;

            await expect(credits.connect(account2).safeBatchTransferFrom(
                account2.address,
                account1.address,
                creditIds,
                [amount, amount],
                "0x00"
            )).
            emit(credits, "TransferBatch")
                .withArgs(
                    account2.address,
                    account2.address,
                    account1.address,
                    creditIds,
                    [amount, amount]
                );

            expect(await credits.balanceOf(account1.address, creditIds[0])).equal(amount);
            expect(await credits.balanceOf(account1.address, creditIds[1])).equal(amount);
            expect(await credits.balanceOf(account2.address, creditIds[0])).equal(0);
            expect(await credits.balanceOf(account2.address, creditIds[1])).equal(0);

            await credits.connect(account1).safeTransferFrom(
                account1.address,
                account2.address,
                creditIds[1],
                amount,
                "0x00"
            );
        });

        it("Sets approval for all", async () => {
            await expect(credits.connect(account1).setApprovalForAll(owner.address, true)).reverted;

            await expect(credits.connect(account1).setApprovalForAll(account2.address, true))
                .emit(credits, "ApprovalForAll")
                .withArgs(
                    account1.address,
                    account2.address,
                    true
                );

            await expect(credits.connect(account2).safeTransferFrom(
                account1.address,
                account2.address,
                creditIds[0],
                amount,
                "0x00"
            )).not.reverted;

            await credits.connect(account2).safeTransferFrom(
                account2.address,
                account1.address,
                creditIds[0],
                amount,
                "0x00"
            );
        });

        it("Updates metadata uri", async () => {
            const newUri = "uri2";

            await expect(credits.connect(account2).updateMetadataUri(newUri)).reverted;

            await expect(credits.updateMetadataUri(newUri))
                .emit(credits, "MetadataUriUpdated")
                .withArgs(
                    newUri
                );

            expect(await credits.uri(1)).equal(newUri);
        });

        it("Gets uri", async () => {
            await expect(credits.uri(0)).reverted;
        });

        it("Gets balance of", async () => {
            expect(await credits.balanceOf(owner.address, 0)).equal(0);
        });

        it("Gets balance of batch", async () => {
            await expect(credits.balanceOfBatch([owner.address], [0, 1])).reverted;
            expect(await credits.balanceOfBatch([owner.address, account1.address], [0, 1])).deep.equal([0, amount]);
        });

        it("Gets approved for all", async () => {
            expect(await credits.isApprovedForAll(account1.address, account2.address)).is.true;
            expect(await credits.isApprovedForAll(account2.address, account1.address)).is.false;
        });
    });

    describe("ERC-5006", () => {
        it("Creates user record", async () => {
            lastDate = new Date();
            lastDate.setDate(lastDate.getDate() + days);
            let timestamp = Math.floor(lastDate.getTime() / 1000);

            await expect(credits.connect(account1).createUserRecord(
                account2.address,
                account1.address,
                creditIds[1],
                amount,
                timestamp
            )).reverted;

            await expect(credits.connect(account2).createUserRecord(
                account2.address,
                owner.address,
                creditIds[1],
                amount,
                timestamp
            )).reverted;

            await expect(credits.connect(account2).createUserRecord(
                account2.address,
                account1.address,
                creditIds[0],
                amount,
                timestamp
            )).reverted;

            for (let i = 0; i < 2; i++) {
                await expect(credits.connect(account2).createUserRecord(
                    account2.address,
                    account1.address,
                    creditIds[1],
                    1,
                    timestamp
                ))
                    .emit(credits, "CreateUserRecord")
                    .withArgs(
                        recordIds.length + 1,
                        creditIds[1],
                        1,
                        account2.address,
                        account1.address,
                        timestamp
                    );
                recordIds.push(recordIds.length + 1);
            }

            const record = await credits.userRecordOf(recordIds[0]);
            expect(record.tokenId).equal(creditIds[1]);
            expect(record.owner).equal(account2.address);
            expect(record.amount).equal(1);
            expect(record.user).equal(account1.address);
            expect(record.expiry).equal(timestamp);

            expect(await credits.usableBalanceOf(account1.address, creditIds[1])).equal(2);
            expect(await credits.frozenBalanceOf(account2.address, creditIds[1])).equal(2);

            await expect(credits.connect(account2).createUserRecord(
                account1.address,
                account2.address,
                creditIds[0],
                1,
                timestamp
            )).not.reverted;
            recordIds.push(recordIds.length + 1);

            expect(await credits.usableBalanceOf(account2.address, creditIds[0])).equal(1);
            expect(await credits.frozenBalanceOf(account1.address, creditIds[0])).equal(1);
        });

        it("Remove user record", async () => {
            await expect(credits.connect(account2).deleteUserRecord(recordIds[0])).reverted;

            lastDate.setDate(lastDate.getDate() + days);
            const newDate = Math.floor(lastDate.getTime() / 1000);
            await ethers.provider.send("evm_mine", [newDate]);

            await expect(credits.connect(account1).deleteUserRecord(recordIds[0])).reverted;

            expect(await credits.usableBalanceOf(account1.address, creditIds[1])).equal(0);
            expect(await credits.frozenBalanceOf(account2.address, creditIds[1])).equal(2);

            await expect(credits.connect(account2).deleteUserRecord(recordIds[0]))
                .emit(credits, "DeleteUserRecord")
                .withArgs(recordIds[0]);

            expect(await credits.frozenBalanceOf(account2.address, creditIds[1])).equal(1);

            await expect(credits.connect(account2).deleteUserRecord(recordIds[0])).reverted;
        });
    });

    describe("Fundings", () => {
        it("Opens phase", async () => {
            await expect(credits.connect(account2).openPhase(
                projectIds[0],
                amount,
                price,
            )).reverted;

            await expect(credits.connect(account1).openPhase(
                projectIds[0],
                amount,
                price,
            ))
                .emit(credits, "PhaseAction")
                .withArgs(
                    phaseIds.length + 1,
                    true,
                    amount,
                    price,
                    false
                );

            await expect(credits.connect(account1).openPhase(
                projectIds[0],
                amount,
                price,
            )).reverted;

            await credits.connect(account1).openPhase(
                projectIds[1],
                amount,
                price,
            );
        });

        it("Buys credits", async () => {
            await token.mintTo(account1.address, price);
            await token.mintTo(account2.address, price * 101);
            await token.mintTo(owner.address, price);

            await expect(credits.buyCredits(projectIds[0], 1)).reverted;

            await token.connect(account1).approve(credits.address, price);
            await expect(credits.connect(account1).buyCredits(projectIds[0], 1))
                .emit(credits, "CreditsPurchased")
                .withArgs(
                    creditIds.length + 1,
                    1,
                    account1.address
                );
            creditIds.push(creditIds.length + 1);

            await token.connect(account2).approve(credits.address, price * 101);
            await expect(credits.connect(account2).buyCredits(projectIds[1], 1))
                .emit(credits, "CreditsPurchased")
                .withArgs(
                    creditIds.length + 1,
                    1,
                    account2.address
                );
            creditIds.push(creditIds.length + 1);

            await expect(credits.connect(account2).buyCredits(projectIds[1], 99)).not.reverted;
            await expect(credits.connect(account2).buyCredits(projectIds[1], 1)).reverted;

            await expect(credits.withdraw(owner.address, price)).reverted;

            expect(await token.balanceOf(credits.address)).equal(amount * price + price);
            expect(await token.balanceOf(account2.address)).equal(1);
        });

        it("Closes phase", async () => {
            await expect(credits.connect(account2).closePhase(projectIds[0], false)).reverted;

            await expect(credits.connect(account1).closePhase(projectIds[0], true))
                .emit(credits, "PhaseAction")
                .withArgs(
                    creditIds.length - 1,
                    false,
                    amount,
                    price,
                    true
                );

            expect(await token.balanceOf(account1.address)).equal(price);
            expect(await credits.balanceOf(account1.address, creditIds.length - 1)).equal(0);

            await expect(credits.withdraw(owner.address, price)).reverted;

            await expect(credits.closePhase(projectIds[1], false))
                .emit(credits, "PhaseAction")
                .withArgs(
                    creditIds.length,
                    false,
                    amount,
                    price,
                    false
                );

            expect(await token.balanceOf(account2.address)).equal(1);
            expect(await credits.balanceOf(account2.address, creditIds.length)).equal(100);

            await expect(credits.withdraw(owner.address, price)).not.reverted;
        });
    });
});
