import hre, { ethers } from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';

async function main() {
    const envPath = '.env';
    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    const network = process.env.HARDHAT_NETWORK!.toUpperCase();
    const envName = `BANK_${network}`;

    if (!envConfig[`ROLES_${network}`]) {
        throw "Role address not specified";
    }
    if (!envConfig[`TOKEN_${network}`]) {
        throw "Token address not specified";
    }
    const rolesAddress = envConfig[`ROLES_${network}`];
    const tokenAddress = envConfig[`TOKEN_${network}`];

    const isLocal = process.env.HARDHAT_NETWORK === 'hardhat';

    console.log("--- DEPLOYING BANK ---");

    const Bank = await ethers.getContractFactory("Bank");

    console.log("Start deployment…");

    const bank = await Bank.deploy(tokenAddress, rolesAddress);
    await bank.waitForDeployment();

    const bankAddress = await bank.getAddress();
    envConfig[envName] = bankAddress;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Bank deployed to ${bankAddress}`);
    console.log(`Awaiting 10 confirmations…`);

    if (!isLocal) {
        const deployTransaction = bank.deploymentTransaction();
        if (deployTransaction !== null) {
            await deployTransaction.wait(10);
        } else {
            throw "Deployment transaction is null";
        }
        console.log(`Done.`);

        console.log("Verifying in etherscan…");
        console.log("Waiting 2 min. for registration…");

        setTimeout(async function () {
            try {
                console.log(`Done.`);
                await hre.run("verify:verify", {
                    address: bankAddress,
                    constructorArguments: [tokenAddress, rolesAddress],
                    network: process.env.HARDHAT_NETWORK
                });
            } catch (e) {
                console.error(e);
            }
        }, 120000);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
