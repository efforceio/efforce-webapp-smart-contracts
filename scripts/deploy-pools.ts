import { ethers } from "hardhat";
import hre from "hardhat";
const fs = require('fs');
const dotenv = require('dotenv');

async function main() {

    let
        rolesAddress = "",
        bankAddress = "",
        envName = "";

    const envPath = '.env';

    console.log("--- DEPLOYING POOLS ---");
    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!envConfig["ROLES_MUMBAI"] || !envConfig["BANK_MUMBAI"]) {
                throw "Roles address, USDC address, or Locking period not set";
            } else {
                rolesAddress = envConfig["ROLES_MUMBAI"];
                bankAddress = envConfig["BANK_MUMBAI"];
                envName = "POOLS_MUMBAI";
            }
            break;
        case 'polygon':
            if (!envConfig["ROLES"] || !envConfig["BANK"]) {
                throw "Roles address, USDC address, or Locking period not set";
            } else {
                rolesAddress = envConfig["ROLES"];
                bankAddress = envConfig["BANK"];
                envName = "POOLS";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Pools = await ethers.getContractFactory("Pools");

    console.log("Start deployment…");

    const pools = await Pools.deploy(
        rolesAddress,
        bankAddress
    );

    await pools.deployed();

    envConfig[envName] = pools.address;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Pools deployed to ${pools.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await pools.deployTransaction.wait(5);
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const roles = Roles.attach(rolesAddress);
    await roles.setAdmin(pools.address, true);

    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: pools.address,
                constructorArguments: [
                    rolesAddress,
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
