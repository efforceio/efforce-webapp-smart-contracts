import { ethers } from "hardhat";
import hre from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Credits as CreditsType, Roles as RolesType } from "../typechain-types";

async function main() {

    let
        creditsAddress = "",
        rolesAddress = "",
        bankAddress = "",
        utilsAddress = "",
        envName = "";

    const envPath = '.env';

    console.log("--- DEPLOYING SWAP ---");
    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (
                !envConfig["CREDITS_MUMBAI"] ||
                !envConfig["BANK_MUMBAI"] ||
                !envConfig["ROLES_MUMBAI"] ||
                !envConfig["UTILS_MUMBAI"]
            ) {
                throw "Credits address, Bank address, Roles address, or Utils address not set";
            } else {
                creditsAddress = envConfig["CREDITS_MUMBAI"];
                bankAddress = envConfig["BANK_MUMBAI"];
                envName = "SWAP_MUMBAI";
                rolesAddress = envConfig["ROLES_MUMBAI"];
                utilsAddress = envConfig["UTILS_MUMBAI"];
            }
            break;
        case 'polygon':
            if (
                !envConfig["CREDITS"] ||
                !envConfig["BANK"] ||
                !envConfig["ROLES"] ||
                !envConfig["UTLS"]
            ) {
                throw "Credits address, Bank address, Roles address, or Utils address not set";
            } else {
                creditsAddress = envConfig["CREDITS"];
                bankAddress = envConfig["BANK"];
                envName = "SWAP";
                rolesAddress = envConfig["ROLES"];
                utilsAddress = envConfig["UTILS"];
            }
            break;
        default:
            throw "Network not supported";
    }

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
