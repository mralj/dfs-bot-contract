import { readBotAddress } from "../helpers";
import { Ethers } from "../types";

export async function withdraw(ethers: Ethers) {
  const bot = await ethers.getContractAt("Bot", await readBotAddress());
  const tx = await bot.withdraw();
  console.log(`[WITHDRAW]: https://bscscan.com/tx/${tx.hash}`);
}

export async function withdrawToken(ethers: Ethers) {
  const withdrawToken = "";

  const bot = await ethers.getContractAt("Bot", await readBotAddress());
  const tx = await bot.withdrawToken(withdrawToken);
  console.log(`[WITHDRAW TOKEN]: https://bscscan.com/tx/${tx.hash}`);
}
