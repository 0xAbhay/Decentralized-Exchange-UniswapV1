const hre = require("hardhat");

async function sleep(ms){
  return new Promise((resolve) => setTimeout(resolve,ms));
}

async function main() {

  // deploy the token contract
  const tokenContract = await hre.ethers.deployContract("MiniToken");
  await tokenContract.waitForDeployment();
  console.log("MiniToken deployed to:", tokenContract.target);

  // deploy the Exchange contract
  const DEXcontract = await hre.ethers.deployContract("DEX",[tokenContract.target]);
  await DEXcontract.waitForDeployment();
  console.log("DEX deployed to:", DEXcontract.target);

  // wait for 30 seconds to let the etherscan  catch up on the contract deployments
  await hre.run("verify:verify",{
    address: tokenContract.target,
    constructorArguments: [],
    contract: "contracts/ERC20Token.sol:MiniToken"
  });

  await hre.run("verify:verify", {
    address: exchangeContract.target,
    constructorArguments: [tokenContract.target],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
