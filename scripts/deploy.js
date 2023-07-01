const { ethers } = require('hardhat');

async function main() {
  const address = '0x77FA39F3aDf09BDE9D4F175E40D0854D21a33318';
  await helpers.impersonateAccount(address);
  const impersonatedSigner = await ethers.getSigner(address);
  const FlashloanReceiver = await ethers.getContractFactory(
    'FlashloanReceiver',
    impersonatedSigner
  );
  const flashloanReceiver = await FlashloanReceiver.deploy();
  await flashloanReceiver.deployed();

  const fr = ethers.utils.hexlify('10000')

  console.log(`FlashloanReceiver deployed to address: ${flashloanReceiver.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
