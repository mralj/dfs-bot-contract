import { readBotAddress } from "../helpers";
import { CUSTOM_GAS_LIMIT, Ethers } from "../types";

export async function buy(ethers: Ethers) {
  const bot = await ethers.getContractAt("Bot", await readBotAddress());
  const tx = await bot.cure({ gasLimit: CUSTOM_GAS_LIMIT });
  console.log(`[BUY]: https://bscscan.com/tx/${tx.hash}`);
}
