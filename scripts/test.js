const { ethers } = require("hardhat"); //https://127.0.0.1:8545/
let provider = new ethers.providers.JsonRpcProvider("https://127.0.0.1:8545");
async function main() {
  const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const USDC_ABI = [
    "function balanceOf(address account) external view returns (uint256)",
    "function transfer(address recipient, uint256 amount) external returns (bool)",
  ];
  const usdc = await ethers.getContractAt("IERC20", USDC_ADDRESS);
  //   await signers[0].sendTransaction({
  //     to: impersonatedSigner.address,
  //     // to: "0x09c01AA4dfaa767f8319A001A1d5eE848f99A44E",
  //     value: ethers.utils.parseEther("50.0"), // Sends exactly 50.0 ether
  //   });
  // const signer = await hre.ethers.getSigners();

  // Get the contract instance

  // const usdc = new ethers.Contract(USDC_ADDRESS, USDC_ABI, provider);
  const balance = await usdc.balanceOf(
    "0x09c01AA4dfaa767f8319A001A1d5eE848f99A44E"
  );
  console.log(balance);
  //   const signers = await hre.ethers.getSigners();
  //   const USDC_WHALE = "0x09c01AA4dfaa767f8319A001A1d5eE848f99A44E";

  //   const impersonatedSigner = await ethers.getImpersonatedSigner(USDC_WHALE);
  //   const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

  //
  //   let newWhaleBal = await usdc.balanceOf(USDC_WHALE);
  //   console.log(newWhaleBal);
  //   let newAttackerBal = await usdc.balanceOf(signers[0].address);

  //   await usdc.connect(impersonatedSigner).transfer(signers[0].address, 10);

  //   newWhaleBal = await usdc.balanceOf(USDC_WHALE);
  //   newAttackerBal = await usdc.balanceOf(owner.address);

  //   console.log(
  //     "Final USDC balance of whale : ",
  //     ethers.utils.formatUnits(newWhaleBal, 6)
  //   );

  //   console.log(
  //     "Final USDC balance of attacker : ",
  //     ethers.utils.formatUnits(newAttackerBal, 6)
  //   );

  //   //   const accounts = [otherAccount, thirdAccount, fourthAccount, fifthAccount];
  //   //   const plan = [1, 2, 3, 1];
  //   //   const timePeriod = [1, 1, 2, 3];
  //   //   const CryptoAssetInsuranceFactory = await hre.ethers.getContractFactory(
  //   //     "CryptoAssetInsuranceFactory"
  //   //   );
  //   //   const _value = await hre.ethers.utils.parseEther("10");
  //   //   const cyptoAssetInsuranceFactory = await CryptoAssetInsuranceFactory.deploy({
  //   //     value: _value,
  //   //   });
  //   //   await cyptoAssetInsuranceFactory.deployed();

  //   //   console.log(
  //   //     `Factory Contract deployed to ${cyptoAssetInsuranceFactory.address}`
  //   //   );
}

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
