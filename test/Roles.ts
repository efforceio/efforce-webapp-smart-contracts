import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Roles } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("Roles test", () => {
    let
        owner: SignerWithAddress,
        account1: SignerWithAddress,
        account2: SignerWithAddress,
        roles: Roles;

    before("Initialization", async () => {
        [owner, account1, account2] = await ethers.getSigners();

        const Roles = await ethers.getContractFactory("Roles");
        roles = await Roles.deploy(owner.address);
    });

    it("Check owner", async () => {
        expect(await roles.getOwner()).equal(owner.address);
    });

    it("Check admins", async () => {
        expect(await roles.isAdmin(account1.address)).false;
    });

    it("Set admins", async () => {
        await expect(roles.connect(account1).setAdmin(account1.address, true)).reverted;

        await expect(roles.setAdmin(account1.address, true))
            .emit(roles, "RoleAssignment")
            .withArgs(account1.address, false, true);
        expect(await roles.isAdmin(account1.address)).true;

        await expect(roles.connect(account1).setAdmin(account1.address, true)).reverted;
        await roles.setAdmin(account2.address, true);

        await expect(roles.setAdmin(account1.address, false))
            .emit(roles, "RoleAssignment")
            .withArgs(account1.address, false, false);
        expect(await roles.isAdmin(account1.address)).false;
    });

    it("Sets contract owner", async () => {
        await expect(roles.connect(account1).setOwner(account1.address)).reverted;
        await expect(roles.connect(account2).setOwner(account1.address)).reverted;
        await expect(roles.setOwner(account1.address))
            .emit(roles, "RoleAssignment")
            .withArgs(account1.address, true, false);
        expect(await roles.getOwner()).equal(account1.address);
    });

});
