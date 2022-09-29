const { ethers } = require("hardhat");
require("dotenv").config({ path: ".env" });
const { CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS } = require("../constants");
async function main() {
  const cryptoDevTokenAddress = CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS;

  //exchangeContract is a factory for instance of our exchange contract
  const exchangeContract = await ethers.getContractFactory("Exchange");

  // we deploy the contract
  const deployedExchangeContract = await exchangeContract.deploy(
    cryptoDevTokenAddress
  );
  await deployedExchangeContract.deployed();
  //finally print the address of the deployed contract
  console.log("Exchange Contract adress:", deployedExchangeContract.address);
}
//call the main function to catch idf there is an error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
