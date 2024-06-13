import { readBotAddress } from "../helpers";
import { CUSTOM_GAS_LIMIT, Ethers } from "../types";

const sellToken = "";

export async function sell(ethers: Ethers) {
  const bot = await ethers.getContractAt("Bot", await readBotAddress());
  const tx = await bot.sellAll(sellToken, { gasLimit: CUSTOM_GAS_LIMIT });
  console.log(`[SELL]: https://bscscan.com/tx/${tx.hash}`);
}
