import { task } from "hardhat/config";
import execute from "../scripts/execute";
import { Ethers } from "../scripts/types";

task(
  "exec",
  "Interact with contract, possible actions are: withdraw, withdrawToken, prep, buy, sell"
)
  .addPositionalParam("action")
  .setAction(async (taskArgs, hre) => {
    const { action } = taskArgs;
    await execute(action, hre.ethers as Ethers);
  });
