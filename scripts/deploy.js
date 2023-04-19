async function main() {
  const [owner, otherAccount, thirdAccount, fourthAccount, fifthAccount] =
    await hre.ethers.getSigners();
  const accounts = [otherAccount, thirdAccount, fourthAccount, fifthAccount];
  const plan = [1, 2, 3, 1];
  const timePeriod = [1, 1, 2, 3];
  const CryptoWalletInsuranceFactory = await hre.ethers.getContractFactory(
    "CryptoWalletInsuranceFactory"
  );
  const cryptoWalletInsuranceFactory =
    await CryptoWalletInsuranceFactory.deploy();
  await cryptoWalletInsuranceFactory.deployed();

  console.log(
    `Factory Contract deployed to ${cryptoWalletInsuranceFactory.address}`
  );
  const contractsArray = await deployStorageContracts(4, accounts);
  await storeValues(contractsArray);
  console.log("Values Stored");

  const getAmount = await getInsuranceAmount(contractsArray, plan, timePeriod);

  await getInsurance(
    plan,
    contractsArray,
    timePeriod,
    cryptoWalletInsuranceFactory,
    accounts,
    getAmount
  );
  console.log("////////////////Insurance Contracts Deployed/////////////////");
}

//Helping Functions
async function deployContract(index, deployer) {
  const Contract = await hre.ethers.getContractFactory("Storage");
  const contract = await Contract.connect(deployer).deploy();
  await contract.deployed();

  console.log("/////DEPLOY CONTRACT/////");
  console.log(
    `Storage ${index} Contract deployed to ${contract.address} by ${deployer.address}`
  );
  console.log("//////");
  return contract;
}
async function deployStorageContracts(quantity, accounts) {
  const contracts = [];
  for (let i = 0; i < quantity; i++) {
    contracts.push(await deployContract(i, accounts[i]));
  }
  return contracts;
}
async function storeValues(contractArray) {
  for (let i = 0; i < contractArray.length; i++) {
    const contract = contractArray[i];
    let _value = hre.ethers.utils.parseEther((i + 1).toString());
    await contract.store({ value: _value });
  }
}

async function getInsurance(
  plans,
  contractArray,
  timePeriods,
  factoryContract,
  accounts,
  getAmount
) {
  for (let i = 0; i < contractArray.length; i++) {
    const contract = contractArray[i];
    const account = accounts[i];
    const plan = plans[i];
    const timePeriod = timePeriods[i];
    const _value = getAmount[i];
    await factoryContract
      .connect(account)
      .getInsurance(plan, contract.address, timePeriod, {
        value: _value,
      });
    console.log("////GET INSURANCE/////");
    console.log(
      `Insurance Contract deployed for ${contract.address}by ${account.address}`
    );
    console.log("/////////");
  }
}

async function getInsuranceAmount(contractArray, plans, timePeriods) {
  let amountPayableArray = [];
  for (let i = 0; i < contractArray.length; i++) {
    const contractBalance = await hre.ethers.provider.getBalance(
      contractArray[i].address
    );
    //Plans are not proportional to amount send directly
    let plan = plans[i];
    if (plan == 2) {
      plan = 5;
    } else if (plan == 3) {
      plan = 10;
    }
    const timePeriod = timePeriods[i];
    const amountPayable = (contractBalance * plan * timePeriod) / 100;
    amountPayableArray.push(amountPayable.toString());
    console.log("///GET INSURANCE AMOUNT/////");
    console.log(
      `Insurance Contract Amount Payable is ${amountPayable} for ${contractArray[i].address}`
    );
    console.log("///////");
  }
  return amountPayableArray;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
