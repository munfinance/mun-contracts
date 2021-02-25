const { ethers, upgrades } = require('hardhat')
const BigNumber = require('bignumber.js')
const baseURI = 'https://munfinance.github.io/mun-server/'

async function main() {
	console.log('Starting')

	const MUN = await ethers.getContractFactory('MUN')
	const mun = await upgrades.deployProxy(MUN, [])
	await mun.deployed()
	console.log('Mun:', mun.address)

	const MUS = await ethers.getContractFactory('MUS')
	const mus = await upgrades.deployProxy(MUS, ['0x0000000000000000000000000000000000000000'])
	await mus.deployed()
	console.log('Mus:', mus.address)

	const LockLiquidity = await ethers.getContractFactory('LockLiquidity')
	const lockLiquidity = await upgrades.deployProxy(LockLiquidity, ['0x0000000000000000000000000000000000000000', mun.address])
	await lockLiquidity.deployed()
	console.log('LockLiquidity:', lockLiquidity.address)

	console.log('Setting variables...')
	await mun.setLockLiquidityContract(lockLiquidity.address)
	await lockLiquidity.setMun(mun.address)

	const NFTManager = await ethers.getContractFactory('NFTManager')
	const manager = await upgrades.deployProxy(NFTManager, [mun.address, mus.address, baseURI])
	await manager.deployed()
	console.log('NFTManager:', manager.address)

	console.log('Setting blueprints...')
	await manager.createBlueprint(
		'lucky-ball.json',
		'10000',
		'100000000000000000',
		'100000000000000000',
	)
	
	await manager.createBlueprint(
		'maximum-bet.json',
		'10000',
		'100000000000000000',
		'100000000000000000',
	)
	await manager.createBlueprint(
		'hidden-surprise.json',
		'10000',
		'100000000000000000',
		'100000000000000000',
	)
	await manager.createBlueprint(
		'bullseye.json',
		'10000',
		'100000000000000000',
		'100000000000000000',
	)

	await manager.createBlueprint(
		'couple-winners.json',
		'3000',
		'1000000000000000000',
		'1000000000000000000',
	)
	await manager.createBlueprint(
		'round-mistery.json',
		'3000',
		'1000000000000000000',
		'1000000000000000000',
	)
	await manager.createBlueprint(
		'roll-to-win.json',
		'3000',
		'1000000000000000000',
		'1000000000000000000',
	)

	await manager.createBlueprint(
		'seven-trio.json',
		'500',
		'10000000000000000000',
		'10000000000000000000',
	)
	await manager.createBlueprint(
		'hit-hop.json',
		'500',
		'10000000000000000000',
		'10000000000000000000',
	)
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
