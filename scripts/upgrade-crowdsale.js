const { ethers, upgrades } = require('hardhat')
const BigNumber = require('bignumber.js')

async function main() {
	console.log('Starting')
    const mun = '0xAd426a9402468e6D1e6F861F2CAAf2Cb5a653Af3'
    const v1 = '0x8Bc3bA0130454AD874C5F2003dd81c2A46db5077'

	const CrowdsaleV2 = await ethers.getContractFactory('CrowdsaleV2')
	const crowdsale = await upgrades.upgradeProxy(v1, CrowdsaleV2)
	await crowdsale.deployed()
	console.log('Crowdsale V2:', crowdsale.address)

	console.log('Done')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
