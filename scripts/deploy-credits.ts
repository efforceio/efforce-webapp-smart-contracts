import { ethers } from "hardhat";

async function main() {

    const Utils = await ethers.getContractFactory("Utils");
    const utils = await Utils.deploy();

    const Credits = await ethers.getContractFactory(
        "Credits",
        {
            libraries: {
                Utils: utils.address
            }
        }
    );
    const credits = await Credits.deploy(
        "0xF40fE06c96Fb6be8cf1995dd039Bb59408656046",
        "metadataURI",
        "contractMetadataURI",
        10_00
    );

    await credits.deployed();

    console.log(`Projects deployed to ${credits.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
