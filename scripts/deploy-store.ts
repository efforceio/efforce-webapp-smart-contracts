import { ethers } from "hardhat";
import hre from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Roles as RolesType, Credits as CreditsType } from "../typechain-types";

async function main() {

    let
        rolesAddress = "",
        creditsAddress = "",
        bankAddress = "",
        utilsAddress = "",
        envName = "";

    const envPath = '.env';

    console.log("--- DEPLOYING STORE ---");

    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (
                !envConfig["ROLES_MUMBAI"] ||
                !envConfig["BANK_MUMBAI"] ||
                !envConfig["CREDITS_MUMBAI"] ||
                !envConfig["UTILS_MUMBAI"]
            ) {
                throw "Roles address, Bank address, or Credits address not set";
            } else {
                rolesAddress = envConfig["ROLES_MUMBAI"];
                bankAddress = envConfig["BANK_MUMBAI"];
                creditsAddress = envConfig["CREDITS_MUMBAI"];
                utilsAddress = envConfig["UTILS_MUMBAI"];
                envName = "STORE_MUMBAI";
            }
            break;
        case 'polygon':
            if (!envConfig["ROLES"] || !envConfig["BANK"] || !envConfig["CREDITS"] || !envConfig["UTILS"]) {
                throw "Roles address, Bank address, or Credits address not set";
            } else {
                rolesAddress = envConfig["ROLES"];
                bankAddress = envConfig["BANK"];
                creditsAddress = envConfig["CREDITS"];
                utilsAddress = envConfig["UTILS"];
                envName = "STORE";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Store = await ethers.getContractFactory("Store");

    console.log("Start deployment…");

    const store = await Store.deploy(
        creditsAddress,
        bankAddress,
        rolesAddress
    );

    await store.waitForDeployment();

    const storeAddress = await store.getAddress();
    envConfig[envName] = storeAddress;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Store deployed to ${storeAddress}`);
    console.log(`Awaiting 10 confirmations…`);

    const deployTransaction = store.deploymentTransaction();

    if (deployTransaction !== null) {
        await deployTransaction.wait(10);
    } else {
        throw "Deployment transaction is null";
    }
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const roles = Roles.attach(rolesAddress) as RolesType;
    let res = await roles.setAdmin(storeAddress, true);
    await res.wait(10);

    console.log(`Done.`);

    console.log(`Setting operator...`);

    const Credits = await ethers.getContractFactory("Credits", {
        libraries: {
            Utils: utilsAddress
        }
    });
    const credits = Credits.attach(creditsAddress) as CreditsType;
    res = await credits.setContractOperator(storeAddress, true);
    await res.wait(10);

    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: storeAddress,
                constructorArguments: [
                    creditsAddress,
                    bankAddress,
                    rolesAddress
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
