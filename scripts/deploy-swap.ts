import { ethers } from "hardhat";
import hre from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Credits as CreditsType, Roles as RolesType } from "../typechain-types";

async function main() {

    const envPath = '.env';
    const envConfig = dotenv.parse(fs.readFileSync(envPath));
    const network = process.env.HARDHAT_NETWORK!.toUpperCase();
    const envName = `SWAP_${network}`;

    if (!envConfig[`CREDITS_${network}`]) {
        throw "Credits address not specified";
    }
    if (!envConfig[`ROLES_${network}`]) {
        throw "Roles address not specified";
    }
    if (!envConfig[`BANK_${network}`]) {
        throw "Bank address not specified";
    }
    if (!envConfig[`UTILS_${network}`]) {
        throw "Utils address not specified";
    }
    const creditsAddress = envConfig[`CREDITS_${network}`];
    const rolesAddress = envConfig[`CREDITS_${network}`];
    const bankAddress = envConfig[`BANK_${network}`];
    const utilsAddress = envConfig[`UTILS_${network}`];

    console.log("--- DEPLOYING SWAP ---");

    const Swap = await ethers.getContractFactory("Swap");

    console.log("Start deployment…");

    const swap = await Swap.deploy(
        creditsAddress,
        bankAddress
    );

    await swap.waitForDeployment();

    const swapAddress = await swap.getAddress();
    envConfig[envName] = swapAddress;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Swap deployed to ${swapAddress}`);
    console.log(`Awaiting 10 confirmations…`);

    const deployTransaction = swap.deploymentTransaction();
    if (deployTransaction !== null) {
        await deployTransaction.wait(10);
    } else {
        throw "Deployment transaction is null";
    }
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const roles = Roles.attach(rolesAddress) as RolesType;
    let res = await roles.setAdmin(swapAddress, true);
    await res.wait(10);

    const Credits = await ethers.getContractFactory("Credits", {
        libraries: {
            Utils: utilsAddress
        }
    });
    const credits = Credits.attach(creditsAddress) as CreditsType;

    console.log(`Allowing swap to receive credits...`);
    res = await credits.updateAccount(swapAddress, true);
    await res.wait(10);

    console.log(`Allowing swap to manage credits...`);
    res = await credits.setContractOperator(swapAddress, true);
    await res.wait(10);

    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: swapAddress,
                constructorArguments: [
                    creditsAddress,
                    bankAddress
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
