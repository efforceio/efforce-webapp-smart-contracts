import hre, { ethers } from "hardhat";
const fs = require('fs');
const dotenv = require('dotenv');

async function main() {
    let
        utils = "",
        roles = "",
        envName = "",
        bank = "";
    const
        metadata = "metadata.json",
        envPath = '.env';

    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    console.log("--- DEPLOYING CREDITS ---");

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!envConfig["UTILS_MUMBAI"] || !envConfig["ROLES_MUMBAI"] || !envConfig["BANK_MUMBAI"]) {
                throw "Utils address, Roles address, or Bank address not set.";
            } else {
                utils = envConfig["UTILS_MUMBAI"];
                roles = envConfig["ROLES_MUMBAI"];
                bank = envConfig["BANK_MUMBAI"];
                envName = "CREDITS_MUMBAI";
            }
            break;
        case 'polygon':
            if (!envConfig["UTILS"] || !envConfig["ROLES"] || !envConfig["BANK"]) {
                throw "Utils address, Roles address, or Bank address not set.";
            } else {
                utils = envConfig["UTILS"];
                roles = envConfig["ROLES"];
                bank = envConfig["BANK"];
                envName = "CREDITS";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Credits = await ethers.getContractFactory(
        "Credits",
        {
            libraries: {
                Utils: utils
            }
        }
    );

    console.log("Start deployment…");

    const credits = await Credits.deploy(
        metadata,
        roles,
        metadata,
        10_00,
        bank
    );

    await credits.deployed();

    envConfig[envName] = credits.address;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Credits deployed to ${credits.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await credits.deployTransaction.wait(5);
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const rolesContract = Roles.attach(roles);
    await rolesContract.setAdmin(credits.address, true);
    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: credits.address,
                constructorArguments: [
                    metadata,
                    roles,
                    metadata,
                    10_00,
                    bank
                ],
                network: process.env.HARDHAT_NETWORK,
                libraries: {
                    Utils: utils
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
