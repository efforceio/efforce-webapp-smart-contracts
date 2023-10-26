import hre, { ethers } from "hardhat";

async function main() {

    const Utils = await ethers.getContractFactory("Utils");

    console.log("Start deployment…");

    const utils = await Utils.deploy();

    await utils.deployed();

    console.log(`Roles deployed to ${utils.address}`);
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
