import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";

describe("Test balances", () => {
  async function deployContract() {
    const Bot = await ethers.getContractFactory("Bot");
    //TODO: properly handle PCS factory address once we add more tests
    const [owner, preparer, seller, other] = await ethers.getSigners();

    const bot = await Bot.deploy(preparer.address, seller.address);

    return { owner, bot, other };
  }

  it("should have 0 balance", async () => {
    const { bot } = await loadFixture(deployContract);
    expect(await bot.balance()).to.equal(0);
  });

  it("should have some balance after sending $$$", async () => {
    const { owner, bot } = await loadFixture(deployContract);

    await owner.sendTransaction({ to: bot.address, value: 1 });
    expect(await bot.balance()).to.equal(1);
  });

  it("should have 0 balance after sending $$$ and then withdrawing", async () => {
    const { owner, bot } = await loadFixture(deployContract);

    await owner.sendTransaction({ to: bot.address, value: 1 });
    expect(await bot.balance()).to.equal(1);

    await bot.withdraw();
    expect(await bot.balance()).to.equal(0);
  });

  it("only admin should be able to withdraw", async () => {
    const { other, bot } = await loadFixture(deployContract);

    await other.sendTransaction({ to: bot.address, value: 1 });
    expect(await bot.balance()).to.equal(1);

    await expect(bot.connect(other).withdraw()).to.be.reverted;
  });
});
