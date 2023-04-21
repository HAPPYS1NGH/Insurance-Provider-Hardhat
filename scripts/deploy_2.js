const { ethers } = require("hardhat");
//0x396862a62b9aA611ccAaD03C8A6a8B18CbC7eB47
require("dotenv").config();
const provider = new ethers.providers.JsonRpcProvider(process.env.URL);
async function main() {
  const accounts = await ethers.getSigners();
  const plan = [1, 2, 3, 1];
  const timePeriod = [1, 1, 2, 3];
  const CryptoWalletInsuranceFactory = await hre.ethers.getContractFactory(
    "CryptoWalletInsuranceFactory"
  );

  const cryptoWalletInsuranceFactory = CryptoWalletInsuranceFactory.attach(
    "0x396862a62b9aA611ccAaD03C8A6a8B18CbC7eB47"
  );

  console.log(`Factory Contract is at ${cryptoWalletInsuranceFactory.address}`);
  const arrayAddress = [
    "0xE20DB454EE2a59ae0f6F058e2bAF7ed3A6E7323b",
    "0xe9694a2A5FCB822B42CE57B15C23bBceF609B201",
    "0x768D728b53a65e9A05f43469FD2F34D62b3BAE2f",
    "0x12AD3E396E2574bf7ADd2D4253Ab27C94B247C74",
  ];
  const contractsArray = await getStorageContracts(arrayAddress);

  const insuranceContractAddresses = await getInsurance(
    contractsArray,
    cryptoWalletInsuranceFactory,
    accounts
  );
  //[
  //   '0x23841F251eECd6ADCEF62F3AFDe1354D879FC2DD',
  //   '0x925Fa3782cAB3777cA243A872771D56357A8E712',
  //   '0xF933C26AE22d126fCE401AD88dd86c0A0f6D8656',
  //   '0x7ab212f4b2F31EE692B620438641fd38A882cc2C'
  // ]
  await getStorageBalance(contractsArray);
  let contractBalance = await provider.getBalance(
    cryptoWalletInsuranceFactory.address
  );
  let bal = hre.ethers.utils.formatEther(contractBalance.toString());
  console.log("Contract balance is " + bal);
  await claimInsurance(accounts, insuranceContractAddresses);
  contractBalance = await provider.getBalance(
    cryptoWalletInsuranceFactory.address
  );
  bal = hre.ethers.utils.formatEther(contractBalance.toString());
  console.log("Contract balance after claim is " + bal);
}

//Helping Functions
async function claimInsurance(accounts, contractArray) {
  const CryptoWalletInsurance = await hre.ethers.getContractFactory(
    "CryptoWalletInsurance"
  );
  for (let i = 0; i < contractArray.length; i++) {
    const contract = await CryptoWalletInsurance.attach(contractArray[i]);
    await contract.connect(accounts[i]).claim();
    console.log(await provider.getBalance(contract.address));
  }
}

async function getContract(address) {
  const Contract = await hre.ethers.getContractFactory("Storage");
  const contract = await Contract.attach(address);
  console.log(`Storage  Contract is  ${contract.address}`);
  return contract;
}
async function getStorageContracts(addresses) {
  const contracts = [];
  for (let i = 0; i < addresses.length; i++) {
    console.log(addresses[i]);
    contracts.push(await getContract(addresses[i]));
  }
  return contracts;
}
async function storeValues(contractArray) {
  for (let i = 0; i < contractArray.length; i++) {
    const contract = contractArray[i];
    let _value = hre.ethers.utils.parseEther(((i + 1) / 10).toString());
    await contract.store({ value: _value });
  }
}
// async function withdrawValues(contract, account) {
//     let _value = await hre.ethers.utils.parseEther("0.15");
//     await contract.connect(account).withdraw(_value);
// }
async function getStorageBalance(contractArray) {
  for (let i = 0; i < contractArray.length; i++) {
    const contract = contractArray[i];
    let _value = await provider.getBalance(contract.address);
    console.log("Value of Storage " + i + " is " + _value);
  }
}

async function getInsurance(contractArray, factoryContract, accounts) {
  const insuranceContractAddresses = [];
  for (let i = 0; i < contractArray.length; i++) {
    const account = accounts[i];
    const insuranceContract = await factoryContract.customerToContract(
      account.address
    );
    insuranceContractAddresses.push(insuranceContract);

    console.log("////GET INSURANCE/////");
    console.log(`The address of NEW INSURANCE is ${insuranceContract}`);
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
