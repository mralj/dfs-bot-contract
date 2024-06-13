import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "./tasks/execute";

const ACCOUNTS = [
  "", // MAIN WALLET
  "", // PREPARER
  "", // SELLER
];

const GAS_PRICE = 3000000000;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: GAS_PRICE,
      accounts: ACCOUNTS,
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: GAS_PRICE,
      accounts: ACCOUNTS,
    },
  },
};

export default config;
