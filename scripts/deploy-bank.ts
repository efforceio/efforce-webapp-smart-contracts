import hre, { ethers } from "hardhat";

async function main() {
    let rolesAddress = "";
    let usdcAddress = "";

    console.log("Reading input…");

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!process.env.ROLES_MUMBAI || !process.env.USDC_MUMBAI) {
                throw "Roles address or usdc address not set";
            } else {
                rolesAddress = process.env.ROLES_MUMBAI || "";
                usdcAddress = process.env.USDC_MUMBAI || "";
            }
            break;
        default:
            throw "Network not supported";
    }

    const Bank = await ethers.getContractFactory("Bank");

    console.log("Start deployment…");

    const bank = await Bank.deploy(usdcAddress, rolesAddress);

    await bank.deployed();

    console.log(`Roles deployed to ${bank.address}`);
    console.log(`Awaiting 5 confirmations…`);

    await bank.deployTransaction.wait(5);

    console.log(`Done.`);
    console.log("Verifying in etherscan…");
    console.log("Waiting 2 min. for registration…");

    setTimeout(async function () {
        try {
            console.log(`Done.`);
            await hre.run("verify:verify", {
                address: bank.address,
                constructorArguments: [usdcAddress, rolesAddress],
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
