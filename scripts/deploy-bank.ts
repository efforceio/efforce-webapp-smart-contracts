import hre, { ethers } from "hardhat";
const fs = require('fs');
const dotenv = require('dotenv');

async function main() {
    let
        rolesAddress = "",
        envName = "",
        usdcAddress = "";

    const envPath = '.env';
    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    console.log("--- DEPLOYING BANK ---");

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!envConfig["ROLES_MUMBAI"] || !envConfig["USDC_MUMBAI"]) {
                throw "Roles address or usdc address not set";
            } else {
                rolesAddress = envConfig["ROLES_MUMBAI"];
                usdcAddress = envConfig["USDC_MUMBAI"];
                envName = "BANK_MUMBAI";
            }
            break;
        case 'polygon':
            if (!envConfig["ROLES"] || !envConfig["USDC"]) {
                throw "Roles address or usdc address not set";
            } else {
                rolesAddress = envConfig["ROLES"];
                usdcAddress = envConfig["USDC"];
                envName = "BANK";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Bank = await ethers.getContractFactory("Bank");

    console.log("Start deployment…");

    const bank = await Bank.deploy(usdcAddress, rolesAddress);

    await bank.deployed();

    envConfig[envName] = bank.address;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Bank deployed to ${bank.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await bank.deployTransaction.wait(5);

    console.log(`Done.`);
    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: bank.address,
                constructorArguments: [usdcAddress, rolesAddress],
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
