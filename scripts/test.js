const { ethers } = require("hardhat");

require("dotenv").config();
const provider = new ethers.providers.JsonRpcProvider(process.env.URL);
async function main() {
  const deployer = await ethers.getSigners();

  console.log(deployer[0].address);
  console.log(deployer[1].address);
  console.log(deployer[2].address);
  console.log(deployer[3].address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
