import hre, { ethers } from "hardhat";
import dotenv from "dotenv";
import fs from "fs";

async function main() {
    let
        address = "",
        envName = "";
    const envPath = '.env';

    console.log("Reading input…");

    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!envConfig["OWNER_MUMBAI"]) {
                throw "Owner address not set";
            } else {
                address = envConfig["OWNER_MUMBAI"];
                envName = "ROLES_MUMBAI";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Roles = await ethers.getContractFactory("Roles");

    console.log("Start deployment…");

    const roles = await Roles.deploy(address);

    await roles.deployed();

    envConfig[envName] = roles.address;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Roles deployed to ${roles.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await roles.deployTransaction.wait(5);

    console.log(`Done.`);
    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: roles.address,
                constructorArguments: [address],
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
