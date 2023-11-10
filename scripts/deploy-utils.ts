import hre, { ethers } from "hardhat";
import dotenv from "dotenv";
import fs from "fs";

async function main() {
    let envName = "";
    const envPath = '.env';

    console.log("--- DEPLOYING UTILS ---");

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            envName = "UTILS_MUMBAI";
            break;
        case 'polygon':
            envName = "UTILS";
            break;
        default:
            throw "Network not supported";
    }

    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    const Utils = await ethers.getContractFactory("Utils");

    console.log("Start deployment…");

    const utils = await Utils.deploy();

    await utils.deployed();

    envConfig[envName] = utils.address;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Utils deployed to ${utils.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await utils.deployTransaction.wait(5);

    console.log(`Done.`);
    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: utils.address,
                constructorArguments: [],
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
