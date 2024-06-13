# Bot

Bot is used to execute buy/sell on blockchain via PCS. This was used by custom
sniping node to snipe liquidity on PCS - this node is one of the fastest on BSC.

## Setup

Just run `npm-install` to install all dependencies and you should be good to go.
This will install:

1. [Hardhat](https://hardhat.org/) - development environment to compile, deploy
   and test smart contracts.
2. [OpenZeppelin](https://openzeppelin.com/) - library of secure smart
   contracts.
3. Other deps, such as prettier, eslint, etc.

Not sure if this is needed, but better to be safe than sorry.

```shell
npx hardhat compile
```

## Testing

```shell
npm test
```

## Hardhat

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
