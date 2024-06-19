import { ethers } from "hardhat";
import hre from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Roles as RolesType, Credits as CreditsType } from "../typechain-types";

async function main() {

    const envPath = '.env';
    const envConfig = dotenv.parse(fs.readFileSync(envPath));
    const network = process.env.HARDHAT_NETWORK!.toUpperCase();
    const envName = `STORE_${network}`;

    if (!envConfig[`ROLES_${network}`]) {
        throw "Roles address not specified";
    }
    if (!envConfig[`BANK_${network}`]) {
        throw "Bank address not specified";
    }
    if (!envConfig[`CREDITS_${network}`]) {
        throw "Credits address not specified";
    }
    if (!envConfig[`UTILS_${network}`]) {
        throw "Utils address not specified";
    }
    const rolesAddress = envConfig[`ROLES_${network}`];
    const bankAddress = envConfig[`BANK_${network}`];
    const creditsAddress = envConfig[`CREDITS_${network}`];
    const utilsAddress = envConfig[`UTILS_${network}`];

    console.log("--- DEPLOYING STORE ---");

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
