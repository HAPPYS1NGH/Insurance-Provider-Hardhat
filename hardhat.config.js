require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    sepolia: {
      url: process.env.URL,
      accounts: [
        process.env.PRIVATE_KEY1,
        process.env.PRIVATE_KEY2,
        process.env.PRIVATE_KEY3,
        process.env.PRIVATE_KEY4,
      ],
    },
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
