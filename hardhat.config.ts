import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.23",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200
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
