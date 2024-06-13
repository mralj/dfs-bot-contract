import { HardhatEthersHelpers } from "hardhat/types";

export type Ethers = typeof import("ethers") & HardhatEthersHelpers;

// we have custom gas limit because it often happens that
// RPC call to estimate gas "fails". By it "fails" I mean that
// usually returned estimated gas limit is much lower than what we need in practice
// issue with this is that TX ends up failing
export const CUSTOM_GAS_LIMIT = 4000000;
