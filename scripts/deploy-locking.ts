import { ethers, upgrades } from "hardhat";
import hre from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Locking as LockingType, Roles as RolesType } from "../typechain-types";

async function main() {

    let
        rolesAddress = "",
        wozxBankAddress = "",
        envName = "";

    const envPath = '.env';

    console.log("--- DEPLOYING LOCKING ---");
    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!envConfig["ROLES_MUMBAI"] || !envConfig["WOZX_BANK_MUMBAI"]) {
                throw "Roles address or WOZX Bank address not set";
            } else {
                rolesAddress = envConfig["ROLES_MUMBAI"];
                wozxBankAddress = envConfig["WOZX_BANK_MUMBAI"];
                envName = "LOCKING_MUMBAI";
            }
            break;
        case 'polygon':
            if (!envConfig["ROLES"] || !envConfig["WOZX_BANK"]) {
                throw "Roles address or Bank address not set";
            } else {
                rolesAddress = envConfig["ROLES"];
                wozxBankAddress = envConfig["WOZX_BANK"];
                envName = "LOCKING";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Locking = await ethers.getContractFactory("Locking");

    console.log("Start deployment…");

    const locking = await upgrades.deployProxy(Locking, []) as unknown as LockingType;
    await locking.waitForDeployment();
    await locking.initializer(wozxBankAddress);

    const lockingAddress = await locking.getAddress();
    envConfig[envName] = lockingAddress;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Locking deployed to ${lockingAddress}`);
    console.log(`Awaiting 10 confirmations…`);

    const deployTransaction = locking.deploymentTransaction();

    if (deployTransaction !== null) {
        await deployTransaction.wait(10);
    } else {
        throw "Deployment transaction is null";
    }
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const roles = Roles.attach(rolesAddress) as RolesType;
    await roles.setAdmin(lockingAddress, true);

    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: lockingAddress,
                constructorArguments: [
                    rolesAddress,
                    wozxBankAddress
                ],
                network: process.env.HARDHAT_NETWORK
            });
        } catch (e) {
            console.error(e);
        }
    }, 120000);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
