import { ethers } from "hardhat";
import hre from "hardhat";
const fs = require('fs');
const dotenv = require('dotenv');

async function main() {

    let
        creditsAddress = "",
        rolesAddress = "",
        bankAddress = "",
        envName = "";

    const envPath = '.env';

    console.log("--- DEPLOYING SWAP ---");
    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!envConfig["CREDITS_MUMBAI"] || !envConfig["BANK_MUMBAI"] || !envConfig["ROLES_MUMBAI"]) {
                throw "Roles address, USDC address, or Locking period not set";
            } else {
                creditsAddress = envConfig["CREDITS_MUMBAI"];
                bankAddress = envConfig["BANK_MUMBAI"];
                envName = "SWAP_MUMBAI";
                rolesAddress = envConfig["ROLES_MUMBAI"];
            }
            break;
        case 'polygon':
            if (!envConfig["CREDITS"] || !envConfig["BANK"] || !envConfig["ROLES"]) {
                throw "Roles address, USDC address, or Locking period not set";
            } else {
                creditsAddress = envConfig["CREDITS"];
                bankAddress = envConfig["BANK"];
                envName = "SWAP";
                rolesAddress = envConfig["ROLES"];
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

    await swap.deployed();

    envConfig[envName] = swap.address;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Pools deployed to ${swap.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await swap.deployTransaction.wait(5);
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const roles = Roles.attach(rolesAddress);
    await roles.setAdmin(swap.address, true);

    console.log(`Allowing swap to receive credits...`);

    const Credits = await ethers.getContractFactory("Credits");
    const credits = Credits.attach(creditsAddress);
    await credits.updateAccount(swap.address, true);
    await credits.setSwapOperator(swap.address);

    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: swap.address,
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
