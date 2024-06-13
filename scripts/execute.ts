import { buy } from "./ca_actions/buy";
import { prep } from "./ca_actions/prep";
import { sell } from "./ca_actions/sell";
import { withdraw, withdrawToken } from "./ca_actions/withdraw";
import { Ethers } from "./types";

export default async function main(action: string, ethers: Ethers) {
  console.log(`Executing action: ${action} ...`);
  switch (action) {
    case "withdraw":
      await withdraw(ethers);
      return;
    case "withdrawToken":
      await withdrawToken(ethers);
      return;
    case "prep":
      await prep(ethers);
      return;
    case "buy":
      await buy(ethers);
      return;
    case "sell":
      await sell(ethers);
      return;
    default:
      console.log(
        `Unknown action: "${action}", supported actions:\n1. withdraw\n2. prep\n3. buy\n4. sell`
      );
      return;
  }
}
