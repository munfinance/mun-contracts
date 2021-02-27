const { ethers, upgrades } = require('hardhat')
const BigNumber = require('bignumber.js')

async function main() {
	console.log('Starting')
    const mun = '0xAd426a9402468e6D1e6F861F2CAAf2Cb5a653Af3'

	const Crowdsale = await ethers.getContractFactory('Crowdsale')
	const crowdsale = await upgrades.deployProxy(Crowdsale, [mun])
	await crowdsale.deployed()
	console.log('Crowdsale:', crowdsale.address)

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
