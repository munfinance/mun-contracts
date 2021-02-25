require("@nomiclabs/hardhat-waffle")
require('@openzeppelin/hardhat-upgrades')
require("@nomiclabs/hardhat-etherscan")
const fs = require('fs')
const privateKey = fs.readFileSync('.secret').toString().trim()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.6.8",
    settings: {
      optimizer: {
        enabled: true,
	      runs: 200,
      }
    }
  },
  networks: {
    bscTestnet: {
      url: 'https://data-seed-prebsc-1-s2.binance.org:8545/',
      chainId: 97,
      accounts: [privateKey],
      gasPrice: 10e9, // 1 gwei
    },
    bsc: {
      url: 'https://bsc-dataseed.binance.org/',
      chainId: 56,
      accounts: [privateKey],
      gasPrice: 3e9, // 1 gwei
    },
    ropsten: {
      url: 'https://ropsten.infura.io/v3/87ac5f84d691494588f2162b15d1523d',
      chainId: 3,
      accounts: [privateKey],
      gasPrice: 10e9, // 1 gwei
    },
  },
  etherscan: {
    apiKey: 'AYZZZ4DRKVPK1N4D4CE6MUBU1PH9PJUHQ8',
  },
}

