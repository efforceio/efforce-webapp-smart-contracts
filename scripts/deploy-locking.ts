import { ethers, upgrades } from "hardhat";
import hre from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Locking as LockingType, Roles as RolesType } from "../typechain-types";

async function main() {

    const envPath = '.env';
    const network = process.env.HARDHAT_NETWORK!.toUpperCase();
    let envName = `LOCKING_${network}`;
    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    if (!envConfig[`ROLES_${network}`]) {
        throw "Roles address not specified";
    }
    if (!envConfig[`BANK_${network}`]) {
        throw "Bank address not specified";
    }
    if (!envConfig[`WOZX_${network}`]) {
        throw "Wozx token address not specified";
    }
    const rolesAddress = envConfig[`ROLES_${network}`];
    const bankAddress =  envConfig[`BANK_${network}`];
    const wozxAddress = envConfig[`WOZX_${network}`];

    console.log("--- DEPLOYING LOCKING ---");

    const Locking = await ethers.getContractFactory("Locking");

    console.log("Start deployment…");

    const locking = await upgrades.deployProxy(Locking, []) as unknown as LockingType;
    await locking.waitForDeployment();
    await locking.initializer(bankAddress, wozxAddress);

    const lockingAddress = await locking.getAddress();
    envConfig[envName] = lockingAddress;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Locking deployed to ${lockingAddress}`);

    console.log(`Awaiting 10 confirmations…`);

    const deployTransaction = locking.deploymentTransaction();

    if (deployTransaction !== null) {
        await deployTransaction.wait(10);
    } else {
        throw "Deployment transaction is null";
    }
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const roles = Roles.attach(rolesAddress) as RolesType;
    await roles.setAdmin(lockingAddress, true);

    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: lockingAddress,
                constructorArguments: [
                    bankAddress,
                    wozxAddress
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
