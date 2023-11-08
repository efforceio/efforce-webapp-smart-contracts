import hre, { ethers } from "hardhat";

async function main() {

    let
        utils = "",
        roles = "",
        bank = "";
    const metadata = "metadata.json";

    console.log("Reading input…");

    switch (process.env.HARDHAT_NETWORK) {
        case 'polygon_mumbai':
            if (!process.env.UTILS_MUMBAI || !process.env.ROLES_MUMBAI || !process.env.BANK_MUMBAI) {
                throw "Utils address not set.";
            } else {
                utils = process.env.UTILS_MUMBAI;
                roles = process.env.ROLES_MUMBAI;
                bank = process.env.BANK_MUMBAI;
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
