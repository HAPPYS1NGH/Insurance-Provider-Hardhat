async function main() {
  const [owner, otherAccount, thirdAccount, fourthAccount, fifthAccount] =
    await hre.ethers.getSigners();

  const CryptoWalletInsuranceFactory = await hre.ethers.getContractFactory(
    "CryptoWalletInsuranceFactory"
  );
  const cryptoWalletInsuranceFactory =
    await CryptoWalletInsuranceFactory.deploy();
  await cryptoWalletInsuranceFactory.deployed();

  console.log(
    `Factory Contract deployed to ${cryptoWalletInsuranceFactory.address}`
  );
  const contractsArray = await deployStorageContracts(4, [
    otherAccount,
    thirdAccount,
    fourthAccount,
    fifthAccount,
  ]);
}
async function deployContract(index, deployer) {
  const Contract = await hre.ethers.getContractFactory("Storage");
  const contract = await Contract.connect(deployer).deploy();
  await contract.deployed();
  console.log(
    `Storage ${index} Contract deployed to ${contract.address} by ${deployer.address}`
  );
  return contract;
}
async function deployStorageContracts(quantity, accounts) {
  const contracts = [];
  for (let i = 0; i < quantity; i++) {
    contracts.push(await deployContract(i, accounts[i]));
  }
  return contracts;
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
