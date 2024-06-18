import hre, { ethers } from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Roles as RolesType } from "../typechain-types";

async function main() {
    let
        utils = "",
        roles = "",
        envName = "",
        bank = "";
    const
        metadata = "metadata.json",
        envPath = '.env';

    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    console.log("--- DEPLOYING CREDITS ---");

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!envConfig["UTILS_MUMBAI"] || !envConfig["ROLES_MUMBAI"] || !envConfig["BANK_MUMBAI"]) {
                throw "Utils address, Roles address, or Bank address not set.";
            } else {
                utils = envConfig["UTILS_MUMBAI"];
                roles = envConfig["ROLES_MUMBAI"];
                bank = envConfig["BANK_MUMBAI"];
                envName = "CREDITS_MUMBAI";
            }
            break;
        case 'polygon':
            if (!envConfig["UTILS"] || !envConfig["ROLES"] || !envConfig["BANK"]) {
                throw "Utils address, Roles address, or Bank address not set.";
            } else {
                utils = envConfig["UTILS"];
                roles = envConfig["ROLES"];
                bank = envConfig["BANK"];
                envName = "CREDITS";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Credits = await ethers.getContractFactory(
        "Credits",
        {
            libraries: {
                Utils: utils
            }
        }
    );

    console.log("Start deployment…");

    const credits = await Credits.deploy(
        metadata,
        roles,
        metadata,
        10_00,
        bank
    );

    await credits.waitForDeployment();

    const creditsAddress = await credits.getAddress();
    envConfig[envName] = creditsAddress;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Credits deployed to ${creditsAddress}`);
    console.log(`Awaiting 10 confirmations…`);

    const deployTransaction = credits.deploymentTransaction();

    if (deployTransaction !== null) {
        await deployTransaction.wait(10);
    } else {
        throw "Deployment transaction is null";
    }
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const rolesContract = Roles.attach(roles) as RolesType;
    await rolesContract.setAdmin(creditsAddress, true);
    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: creditsAddress,
                constructorArguments: [
                    metadata,
                    roles,
                    metadata,
                    10_00,
                    bank
                ],
                network: process.env.HARDHAT_NETWORK,
                libraries: {
                    Utils: utils
                }
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
