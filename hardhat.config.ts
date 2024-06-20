import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-verify";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.23",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 1000
      },
    }
  },
  networks: {
    hardhat: {},
    testnet: {
      url: "https://80002.rpc.thirdweb.com",
      accounts: [process.env.PRIVATE_KEY || ""]
    },
    mainnet: {
      url: "https://137.rpc.thirdweb.com",
      accounts: [process.env.PRIVATE_KEY || ""]
    }
  },
  etherscan: {
    apiKey: {
      polygonAmoy: process.env.POLYGON_AMOY_API_KEY || "",
    }
  }
};

export default config;
