import { ethers, upgrades } from "hardhat";
import hre from "hardhat";
import fs from 'fs';
import dotenv from 'dotenv';
import { Pools as PoolsType, Roles as RolesType } from "../typechain-types";

async function main() {

    const envPath = '.env';
    const envConfig = dotenv.parse(fs.readFileSync(envPath));
    const network = process.env.HARDHAT_NETWORK!.toUpperCase();
    const envName = `POOLS_${network}`;

    if (!envConfig[`ROLES_${network}`]) {
        throw "Roles address not specified";
    }
    if (!envConfig[`BANK_${network}`]) {
        throw "Bank address not specified";
    }
    const bankAddress =  envConfig[`BANK_${network}`];
    const rolesAddress = envConfig[`ROLES_${network}`];

    console.log("--- DEPLOYING POOLS ---");

    const Pools = await ethers.getContractFactory("Pools");

    console.log("Start deployment…");

    const pools = await upgrades.deployProxy(Pools, []) as unknown as PoolsType;
    await pools.waitForDeployment();

    console.log(rolesAddress, bankAddress)
    await pools.initializer(rolesAddress, bankAddress);

    const poolsAddress = await pools.getAddress();
    envConfig[envName] = poolsAddress;
    fs.writeFileSync('.env', Object.keys(envConfig).map(key => `${key}=${envConfig[key]}`).join('\n'));

    console.log(`Pools deployed to ${poolsAddress}`);

    console.log(`Awaiting 10 confirmations…`);

    const deployTransaction = pools.deploymentTransaction();

    if (deployTransaction !== null) {
        await deployTransaction.wait(10);
    } else {
        throw "Deployment transaction is null";
    }
    console.log(`Done.`);

    console.log(`Granting admin role to contract...`);

    const Roles = await ethers.getContractFactory("Roles");
    const roles = Roles.attach(rolesAddress) as RolesType;
    await roles.setAdmin(poolsAddress, true);

    console.log(`Done.`);

    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: poolsAddress,
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
