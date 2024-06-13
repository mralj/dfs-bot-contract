import * as fs from "node:fs/promises";

const CA_ADDRESS_FILE_NAME = "ca.json";

export async function readBotAddress() {
  const jsonFile = await fs.readFile(CA_ADDRESS_FILE_NAME, "utf8");
  const { address } = JSON.parse(jsonFile);
  return address;
}

export async function writeBotAddress(address: string) {
  try {
    await fs.writeFile(CA_ADDRESS_FILE_NAME, JSON.stringify({ address }));
    console.log(`Contract address saved to ${CA_ADDRESS_FILE_NAME}`);
  } catch (error) {
    console.error(
      `Could not save contract address to ${CA_ADDRESS_FILE_NAME}, error: ${error}`
    );
  }
}
