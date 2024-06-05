import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
import "@nomicfoundation/hardhat-toolbox";

require('@openzeppelin/hardhat-upgrades');

const config = {
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
    polygon_mumbai: {
      url: "https://mumbai.rpc.thirdweb.com",
      accounts: [process.env.PRIVATE_KEY || ""]
    },
    polygon: {
      url: "https://polygon.rpc.thirdweb.com",
      accounts: [process.env.PRIVATE_KEY || ""]
    }
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYSCAN_API_KEY || "",
    }
  }
};

export default config;
