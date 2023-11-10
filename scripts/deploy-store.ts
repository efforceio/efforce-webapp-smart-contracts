import { ethers } from "hardhat";
import hre from "hardhat";
const fs = require('fs');
const dotenv = require('dotenv');

async function main() {

    let
        rolesAddress = "",
        creditsAddress = "",
        bankAddress = "",
        envName = "";

    const envPath = '.env';

    console.log("--- DEPLOYING STORE ---");

    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!envConfig["ROLES_MUMBAI"] || !envConfig["BANK_MUMBAI"] || !envConfig["CREDITS_MUMBAI"]) {
                throw "Roles address, USDC address, or Locking period not set";
            } else {
                rolesAddress = envConfig["ROLES_MUMBAI"];
                bankAddress = envConfig["BANK_MUMBAI"];
                creditsAddress = envConfig["CREDITS_MUMBAI"];
                envName = "STORE_MUMBAI";
            }
            break;
        case 'polygon':
            if (!envConfig["ROLES"] || !envConfig["BANK"] || !envConfig["CREDITS"]) {
                throw "Roles address, USDC address, or Locking period not set";
            } else {
                rolesAddress = envConfig["ROLES"];
                bankAddress = envConfig["BANK"];
                creditsAddress = envConfig["CREDITS"];
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

    await store.deployed();

    envConfig[envName] = store.address;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Store deployed to ${store.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await store.deployTransaction.wait(5);
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const roles = Roles.attach(rolesAddress);
    await roles.setAdmin(store.address, true);

    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: store.address,
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
