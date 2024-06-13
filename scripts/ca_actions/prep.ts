import { readBotAddress } from "../helpers";
import { Ethers } from "../types";

const buyToken = "";

const prepConfig = {
  buyToken,
  liqToken: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", // WBNB
  buyAmount: 1,
  skipTest: true,
  testThreshold: 2,
  sellCount: 1,
  firstSellPercent: 100,
  percentOfTokensToKeep: 0,
  buyLimit: 100,
};

export async function prep(ethers: Ethers) {
  const bot = await ethers.getContractAt("Bot", await readBotAddress());

  const tx = await bot.prep(
    prepConfig.liqToken,
    prepConfig.buyToken,
    ethers.BigNumber.from(prepConfig.buyAmount),
    prepConfig.skipTest,
    prepConfig.testThreshold,
    prepConfig.sellCount,
    prepConfig.firstSellPercent,
    prepConfig.percentOfTokensToKeep,
    prepConfig.buyLimit,
  );

  console.log(`[PREP]: https://bscscan.com/tx/${tx.hash}`);
}
