import { ethers } from "hardhat";
import { writeBotAddress } from "./helpers";

async function main() {
  const [deployer, preparer, seller] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Bot = await ethers.getContractFactory("Bot");
  //TODO: add preparer and seller addresses
  const bot = await Bot.deploy(preparer.address, seller.address);

  await bot.deployed();

  console.log(`Bot deployed to: https://bscscan.com/address/${bot.address}`);

  const tx = await deployer.sendTransaction({
    to: bot.address,
    value: ethers.utils.parseEther("0.01"),
  });

  console.log(
    `Sent 0.01 BNB to the contract, tx: https://bscscan.com/tx/${tx.hash}`
  );

  await writeBotAddress(bot.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
