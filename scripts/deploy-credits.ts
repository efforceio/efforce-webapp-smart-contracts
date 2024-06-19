import hre, { ethers } from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Roles as RolesType } from "../typechain-types";

async function main() {
    const
        metadata = "metadata.json",
        envPath = '.env';

    const envConfig = dotenv.parse(fs.readFileSync(envPath));
    const network = process.env.HARDHAT_NETWORK!.toUpperCase();
    let envName = `CREDITS_${network}`;

    if (!envConfig[`UTILS_${network}`]) {
        throw "Utils address not specified";
    }
    if (!envConfig[`ROLES_${network}`]) {
        throw "Roles address not specified";
    }
    if (!envConfig[`BANK_${network}`]) {
        throw "Bank address not specified";
    }
    const utilsAddress = envConfig[`UTILS_${network}`];
    const rolesAddress = envConfig[`ROLES_${network}`];
    const bankAddress = envConfig[`BANK_${network}`];

    console.log("--- DEPLOYING CREDITS ---");

    const Credits = await ethers.getContractFactory(
        "Credits",
        {
            libraries: {
                Utils: utilsAddress
            }
        }
    );

    console.log("Start deployment…");

    const credits = await Credits.deploy(
        metadata,
        rolesAddress,
        metadata,
        10_00,
        bankAddress
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
    const rolesContract = Roles.attach(rolesAddress) as RolesType;
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
                    rolesAddress,
                    metadata,
                    10_00,
                    bankAddress
                ],
                network: process.env.HARDHAT_NETWORK,
                libraries: {
                    Utils: utilsAddress
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
