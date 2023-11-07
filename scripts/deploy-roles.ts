import hre, { ethers } from "hardhat";

async function main() {
    let address = "";

    console.log("Reading input…");

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!process.env.OWNER_MUMBAI) {
                throw "Owner address not set";
            } else {
                address = process.env.OWNER_MUMBAI || "";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Roles = await ethers.getContractFactory("Roles");

    console.log("Start deployment…");

    const roles = await Roles.deploy(address);

    await roles.deployed();

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
