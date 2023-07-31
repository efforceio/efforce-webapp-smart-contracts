import { ethers } from "hardhat";

async function main() {

    const Utils = await ethers.getContractFactory("Utils");
    const utils = await Utils.deploy();

    const Main = await ethers.getContractFactory(
        "Main",
        {
            libraries: {
                Utils: utils.address
            }
        }
    );
    const main = await Main.deploy(
        "0xF40fE06c96Fb6be8cf1995dd039Bb59408656046",
        "metadataURI",
        "contractMetadataURI",
        10_00
    );

    await main.deployed();

    console.log(`Projects deployed to ${main.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
