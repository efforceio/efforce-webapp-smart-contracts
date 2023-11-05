import { ethers } from "hardhat";
import hre from "hardhat";

async function main() {

    let rolesAddress = "";
    let usdcAddress = "";

    console.log("Reading input…");

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!process.env.ROLES_MUMBAI || !process.env.USDC_MUMBAI) {
                throw "Roles address, USDC address, or Locking period not set";
            } else {
                rolesAddress = process.env.ROLES_MUMBAI;
                usdcAddress = process.env.USDC_MUMBAI;
            }
            break;
        default:
            throw "Network not supported";
    }

    const Pools = await ethers.getContractFactory("Pools");

    console.log("Start deployment…");

    const pools = await Pools.deploy(
        rolesAddress,
        usdcAddress
    );

    await pools.deployed();

    console.log(`Pools deployed to ${pools.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await pools.deployTransaction.wait(5);

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
                    usdcAddress
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
