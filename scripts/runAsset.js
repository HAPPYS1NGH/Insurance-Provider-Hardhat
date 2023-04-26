async function main() {
  const [owner, otherAccount, thirdAccount, fourthAccount, fifthAccount] =
    await hre.ethers.getSigners();
  const accounts = [otherAccount, thirdAccount, fourthAccount, fifthAccount];
  const plan = [1, 2, 3, 1];
  const timePeriod = [1, 1, 2, 3];
  const CryptoAssetInsuranceFactory = await hre.ethers.getContractFactory(
    "CryptoAssetInsuranceFactory"
  );
  const _value = await hre.ethers.utils.parseEther("10");
  const cyptoAssetInsuranceFactory = await CryptoAssetInsuranceFactory.deploy({
    value: _value,
  });
  await cyptoAssetInsuranceFactory.deployed();

  console.log(
    `Factory Contract deployed to ${cyptoAssetInsuranceFactory.address}`
  );
  const contractsArray = await deployStorageContracts(4, accounts);
  await storeValues(contractsArray);
  console.log("Values Stored");

  const getAmount = await getInsuranceAmount(contractsArray, plan, timePeriod);

  const insuranceContractAddresses = await getInsurance(
    plan,
    contractsArray,
    timePeriod,
    cyptoAssetInsuranceFactory,
    accounts,
    getAmount
  );
  console.log("////////////////Insurance Contracts Deployed/////////////////");
  await getStorageBalance(contractsArray);
  await withdrawValues(contractsArray);
  console.log("Values withdrawn");
  await getStorageBalance(contractsArray);

  const contractBalance = await hre.ethers.provider.getBalance(
    cyptoAssetInsuranceFactory.address
  );
  const bal = hre.ethers.utils.formatEther(contractBalance.toString());
  console.log("Contract balance is " + bal);
  await claimInsurance(accounts, insuranceContractAddresses);
}
async function claimInsurance(accounts, contractArray) {
  const AssetWalletInsurance = await hre.ethers.getContractFactory(
    "AssetWalletInsurance"
  );
  for (let i = 0; i < contractArray.length; i++) {
    const contract = await AssetWalletInsurance.attach(contractArray[i]);
    await contract.connect(accounts[i]).claim();
    console.log(await hre.ethers.provider.getBalance(contract.address));
  }
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
async function withdrawValues(contractArray) {
  for (let i = 0; i < contractArray.length; i++) {
    const contract = contractArray[i];
    let _value = hre.ethers.utils.parseEther((i + 0.5).toString());
    await contract.withdraw(_value);
  }
}
async function getStorageBalance(contractArray) {
  for (let i = 0; i < contractArray.length; i++) {
    const contract = contractArray[i];
    let _value = await hre.ethers.provider.getBalance(contract.address);
    console.log("Value of " + i + " is " + _value);
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
  const insuranceContractAddresses = [];
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
    const insuranceContract = await factoryContract.customerToContract(
      account.address
    );
    insuranceContractAddresses.push(insuranceContract);

    console.log("////GET INSURANCE/////");
    console.log(
      `Insurance Contract deployed for ${contract.address} by ${account.address} and the address of NEW INSURANCE is ${insuranceContract}`
    );
    console.log("/////////");
  }
  return insuranceContractAddresses;
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
    console.log(
      `Insurance Contract Amount Payable is ${amountPayable} for ${contractArray[i].address}`
    );
  }
  return amountPayableArray;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
