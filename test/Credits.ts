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
        lastDate: Date;

    const
        metadataURI = "uri.metadata",
        contractMetadataURI = "contract.metadata.uri",
        royaltyBps = 10_00,
        amount = 100,
        price = 1,
        zeroAddress = "0x0000000000000000000000000000000000000000",
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

    describe("Projects", () => {
        it("Creates project", async () => {
            await expect(credits.connect(account2).createProject()).reverted;

            await expect(credits.connect(account1).createProject())
                .emit(credits, "ProjectCreation")
                .withArgs(projectIds.length);
            projectIds.push(projectIds.length + 1);

            await expect(credits.createProject())
                .emit(credits, "ProjectCreation")
                .withArgs(projectIds.length);
            projectIds.push(projectIds.length + 1);

            expect(await credits.numberOfProjects()).equal(projectIds.length);
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

    describe("Vintages", () => {
        it("Open new vintage", async () => {
            await expect(credits.connect(account2).openVintage(0, amount, price)).reverted;

            await expect(credits.connect(account1).openVintage(0, amount, price))
                .emit(credits, "VintageOpened")
                .withArgs(creditIds.length, amount, price, 0);
            creditIds.push(creditIds.length + 1);

            await expect(credits.openVintage(1, amount, price))
                .emit(credits, "VintageOpened")
                .withArgs(creditIds.length, amount, price, 1);
            creditIds.push(creditIds.length + 1);

            const details = await credits.getVintage(0);
            expect(details.price).equal(price);
            expect(details.totalCredits).equal(amount);
            expect(details.availableCredits).equal(amount);
            expect(details.state).equal(0);
            expect(details.projectId).equal(0);
        });
        it("Close vintage", async () => {
            await expect(credits.connect(account2).updateVintageState(0, 1)).reverted;

            await expect(credits.connect(account1).updateVintageState(0, 1))
                .emit(credits, "VintageAction")
                .withArgs(0, 1);

            await expect(credits.updateVintageState(1, 1))
                .emit(credits, "VintageAction")
                .withArgs(1, 1);

            await expect(credits.updateVintageState(0, 2)).reverted;
            await expect(credits.updateVintageState(1, 2)).reverted;

            await expect(credits.openVintage(0, amount, price)).not.reverted;
            creditIds.push(creditIds.length + 1);

            await expect(credits.openVintage(1, amount, price)).not.reverted;
            creditIds.push(creditIds.length + 1);
        });
        it("Cancel vintage", async () => {
            await expect(credits.connect(account2).updateVintageState(0, 2)).reverted;

            await expect(credits.connect(account1).updateVintageState(2, 2))
                .emit(credits, "VintageAction")
                .withArgs(2, 2);

            await expect(credits.updateVintageState(3, 2))
                .emit(credits, "VintageAction")
                .withArgs(3, 2);

            await expect(credits.updateVintageState(0, 1)).reverted;
            await expect(credits.updateVintageState(1, 1)).reverted;
        });
    });

    describe("Store", () => {
        before("Distribute tokens", async () => {
            await token.mintTo(owner.address, price * amount);
            await token.mintTo(account1.address, price * amount);
            await token.mintTo(account2.address, price * amount);

            await token.approve(credits.address, price * amount);
            await token.connect(account1).approve(credits.address, price * amount);
            await token.connect(account2).approve(credits.address, price * amount);
        });
        it("Buys credits", async () => {
            await expect(credits.openVintage(0, amount, price)).not.reverted;
            creditIds.push(creditIds.length + 1);

            await expect(credits.openVintage(1, amount, price)).not.reverted;
            creditIds.push(creditIds.length + 1);

            await expect(credits.buyCredits(4, 1)).reverted;

            await expect(credits.connect(account1).buyCredits(4, 1))
                .emit(credits, "CreditsPurchased")
                .withArgs(4, 1, account1.address)

            expect((await credits.getVintage(4)).availableCredits).equal(amount - 1);
            expect(await credits.getPendingCredits(4, account1.address)).equal(1);

            await expect(credits.connect(account2).buyCredits(4, amount)).reverted;
        });
        it("Buys credits for", async () => {
            await expect(credits.connect(account2).buyCreditsFor(4, 1, account2.address)).reverted;

            await expect(credits.buyCreditsFor(4, 1, account1.address))
                .emit(credits, "CreditsPurchased")
                .withArgs(4, 1, account1.address)

            expect((await credits.getVintage(4)).availableCredits).equal(amount - 2);
            expect(await credits.getPendingCredits(4, account1.address)).equal(2);

            await expect(credits.connect(account2).buyCredits(4, amount)).reverted;
        });
        it("Buys and close vintage", async () => {
            await expect(credits.connect(account1).buyCredits(4, amount - 2))
                .emit(credits, "CreditsPurchased")
                .withArgs(4, amount - 2, account1.address)
                .emit(credits, "VintageAction")
                .withArgs(4, 1);
            expect((await credits.getVintage(4)).state).equal(1);
        });
        it("Redeems credits", async () => {
            await expect(credits.connect(account2).redeemCredits(4)).reverted;
            await expect(credits.connect(account1).redeemCredits(4))
                .emit(credits, "RefundOrRedeem")
                .withArgs(account1.address, 4, 1)
                .emit(credits, "TransferSingle")
                .withArgs(account1.address, zeroAddress, account1.address, 4, amount);
            expect(await credits.balanceOf(account1.address, 4)).equal(amount);

            expect(await credits.getPendingCredits(4, account1.address)).equal(0);
            await expect(credits.connect(account1).redeemCredits(4)).reverted;
        });
        it("Refunds credits", async () => {
            await credits.connect(account2).buyCredits(5, 1);
            await credits.updateVintageState(5, 2);

            await expect(credits.connect(account2).refundCredits(5))
                .emit(credits, "RefundOrRedeem")
                .withArgs(account2.address, 5, 2)

            expect(await token.balanceOf(account2.address)).equal(price * amount);
            expect(await credits.getPendingCredits(5, account2.address)).equal(0);
            await expect(credits.connect(account2).refundCredits(5)).reverted;

            expect(await credits.balanceOf(account1.address, 5)).equal(0);
        });
    });

    describe("ERC1155", () => {
        it("Transfers credits", async () => {
            await expect(credits.connect(account1).safeTransferFrom(account1.address, owner.address, 4, 1, []))
                .reverted;
            await expect(credits.connect(account2).safeTransferFrom(account1.address, account2.address, 4, 1, []))
                .reverted;

            await expect(credits.connect(account1).safeTransferFrom(account1.address, account2.address, 4, 1, []))
                .emit(credits, "TransferSingle")
                .withArgs(account1.address, account1.address, account2.address, 4, 1);
            expect(await credits.balanceOf(account2.address, 4)).equal(1);
        });
        it("Transfers credits batch", async () => {
            await expect(
                credits.connect(account1).safeBatchTransferFrom(account1.address, owner.address, [4], [1], [])
            ).reverted;
            await expect(
                credits.connect(account2).safeBatchTransferFrom(account1.address, account2.address, [4], [1], [])
            ).reverted;

            await expect(
                credits.connect(account1).safeBatchTransferFrom(account1.address, account2.address, [4], [1], [])
            )
                .emit(credits, "TransferBatch")
                .withArgs(account1.address, account1.address, account2.address, [4], [1]);
            expect(await credits.balanceOf(account2.address, 4)).equal(2);
        });
        it("Gets balances of batch", async () => {
            expect(await credits.balanceOfBatch([account2.address, account1.address], [4, 4]))
                .deep.equal([2, 98]);
        });
        it("Approves all", async () => {
            await expect(credits.connect(account1).setApprovalForAll(account2.address, true))
                .emit(credits, "ApprovalForAll")
                .withArgs(account1.address, account2.address, true);
            expect(await credits.isApprovedForAll(account1.address, account2.address)).true;

            await expect(credits.connect(account2).safeTransferFrom(account1.address, account2.address, 4, 1, []))
                .not.reverted;

            await expect(credits.connect(account1).setApprovalForAll(account2.address, false))
                .emit(credits, "ApprovalForAll")
                .withArgs(account1.address, account2.address, false);
            expect(await credits.isApprovedForAll(account1.address, account2.address)).false;

            await expect(credits.connect(account2).safeTransferFrom(account1.address, account2.address, 4, 1, []))
                .reverted;
        });
        it("Updates metadata URI", async () => {
            const newUri = "testNewURI";

            await expect(credits.connect(account2).updateMetadataUri(newUri)).reverted;

            await expect(credits.connect(account1).updateMetadataUri(newUri))
                .emit(credits, "MetadataUriUpdated")
                .withArgs(newUri);

            await expect(credits.updateMetadataUri(metadataURI))
                .emit(credits, "MetadataUriUpdated")
                .withArgs(metadataURI);
        });
    });

    describe("ERC-5679", () => {
        it("Mints credits", async () => {
            await credits.openVintage(1, 0, 0);

            await expect(credits.connect(account2).safeMint(owner.address, 6, 1, [])).reverted;
            await expect(credits.safeMint(owner.address, 6, 1, [])).reverted;

            await expect(credits.safeMint(account1.address, 6, 1, []))
                .emit(credits, "TransferSingle")
                .withArgs(owner.address, zeroAddress, account1.address, 6, 1);

            await expect(credits.safeMintBatch(account1.address, [6], [1], [])).not.reverted;

            const vintage = await credits.getVintage(6);

            expect(vintage.totalCredits).equal(2);
            expect(vintage.availableCredits).equal(0);
            expect(await credits.balanceOf(account1.address, 6)).equal(2);
        });
        it("Burn credits", async () => {
            await expect(credits.burn(account2.address, 4, 1, [])).reverted;

            await expect(credits.connect(account2).burn(account2.address, 4, 1, []))
                .emit(credits, "TransferSingle")
                .withArgs(account2.address, account2.address, zeroAddress, 4, 1);

            await expect(credits.connect(account2).burnBatch(account2.address, [4], [1], []))
                .emit(credits, "TransferBatch")
                .withArgs(account2.address, account2.address, zeroAddress, [4], [1]);
        });
    });

    describe("ERC-5006", () => {
        it("Creates user record", async () => {
            lastDate = new Date();
            lastDate.setDate(lastDate.getDate() + days);
            let timestamp = Math.floor(lastDate.getTime() / 1000);

            await expect(credits.connect(account2).createUserRecord(
                account1.address,
                account2.address,
                4,
                1,
                timestamp
            )).reverted;

            await expect(credits.connect(account1).createUserRecord(
                account1.address,
                owner.address,
                4,
                1,
                timestamp
            )).reverted;

            await expect(credits.connect(account1).createUserRecord(
                account1.address,
                account2.address,
                4,
                1,
                timestamp
            ))
                .emit(credits, "CreateUserRecord")
                .withArgs(
                    0,
                    4,
                    1,
                    account1.address,
                    account2.address,
                    timestamp
                );

            const record = await credits.userRecordOf(0);
            expect(record.tokenId).equal(4);
            expect(record.owner).equal(account1.address);
            expect(record.amount).equal(1);
            expect(record.user).equal(account2.address);
            expect(record.expiry).equal(timestamp);

            expect(await credits.usableBalanceOf(account2.address, 4)).equal(1);
            expect(await credits.frozenBalanceOf(account1.address, 4)).equal(1);

            await expect(credits.connect(account1).safeTransferFrom(account1.address, account2.address, 4, 97, []))
                .reverted;
            await expect(credits.connect(account1).safeTransferFrom(account1.address, account2.address, 4, 96, []))
                .not.reverted;
        });

        it("Remove user record", async () => {
            await expect(credits.connect(account1).deleteUserRecord(0)).reverted;

            lastDate.setDate(lastDate.getDate() + days);
            const newDate = Math.floor(lastDate.getTime() / 1000);
            await ethers.provider.send("evm_mine", [newDate]);

            await expect(credits.connect(account1).deleteUserRecord(0))
                .emit(credits, "DeleteUserRecord")
                .withArgs(0);

            expect(await credits.frozenBalanceOf(account1.address, 0)).equal(0);
            expect(await credits.usableBalanceOf(account2.address, 0)).equal(0);
        });
    });
});
