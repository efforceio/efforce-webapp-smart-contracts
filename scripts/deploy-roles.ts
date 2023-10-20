import { ethers } from "hardhat";

async function main() {

    const Roles = await ethers.getContractFactory("Roles");
    const roles = await Roles.deploy("0xF40fE06c96Fb6be8cf1995dd039Bb59408656046");

    await roles.deployed();

    console.log(`Roles deployed to ${roles.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
