const ethers = require('ethers');
const provider = new ethers.AlchemyProvider('mainnet', 'O50flWlUGwM-q9tVqN08JqobdWvNAK05');

const IUniswapV2Router02 = require('@uniswap/v2-periphery/build/IUniswapV2Router02.json');
const IUniswapV2Factory = require('@uniswap/v2-core/build/IUniswapV2Factory.json');
const IUniswapV2Pair = require('@uniswap/v2-core/build/IUniswapV2Pair.json');

const routerAbi = IUniswapV2Router02.abi;
const factoryAbi = IUniswapV2Factory.abi;
const pairAbi = IUniswapV2Pair.abi;

const router1Address = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D'; //Uniswap
const router2Address = '0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F';

const tokenAddress = '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984'; // The token address you want to trade = UNI
const WETHAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; // Assuming the other token is WETH
const USDCAddress = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const USDCDecimal = 1000000000000n;

const privateKey = 'dee06c19fad9dc8380e5df17633e2d5e3ff6c5357f861c2c733775a11de9a853';
const wallet = new ethers.Wallet(privateKey, provider);
const signer = wallet.connect(provider);

const compareAndTrade = async () => {
  const amount = 2000000;
  const tokenAAddress = WETHAddress;
  const tokenBAddress = USDCAddress;
  const [router1Price, router2Price ] =
    await Promise.all([
      getPairPrice(router1Address, routerAbi, factoryAbi, pairAbi, tokenAAddress, tokenBAddress, amount),
      getPairPrice(router2Address, routerAbi, factoryAbi, pairAbi, tokenBAddress, tokenAAddress, amount),
    ]);
  //comparison not working as expected
  const tokenToBuy = tokenAAddress;
  const tokenToSell = tokenBAddress;
  let routerToBuy, routerToSell, buyPrice, sellPrice;
  if (router1Price < router2Price) {
    routerToBuy = router1Address;
    routerToSell = router2Address;
    buyPrice = router1Price;
    sellPrice = router2Price;
  } else if (router2Price < router1Price) {
    routerToBuy = router2Address;
    routerToSell = router1Address;
    buyPrice = router2Price;
    sellPrice = router1Price;
  }
  //   const routerToBuy = router1Price < router2Price ? router1Address : router2Address;
  //   const routerToSell = router2Price < router1Price ? router2Address : router1Address;

  if (sellPrice > buyPrice) {
    console.log('###',routerToBuy, routerToSell, buyPrice, sellPrice)
    // call function
  }
};

const getPairPrice = async (routerAddress, routerAbi, factoryAbi, pairAbi, token0, token1, amount) => {
  const routerContract = new ethers.Contract(routerAddress, routerAbi, provider);
  const pairAddress = await getPairAddress(routerContract, factoryAbi, token0, token1);
  const pairContract = new ethers.Contract(pairAddress, pairAbi, signer);
  const { token0ReserveFormatted, token1ReserveFormatted } = await formatToken();
  const price = token0ReserveFormatted / token1ReserveFormatted;
//   const quote = await routerContract.getAmountOut(amount, token0Reserve, token1Reserve);
  return price;

  async function formatToken() {
    const [token0Reserve, token1Reserve] = await pairContract.getReserves();
    const token0ReserveFormatted = ethers.formatEther(token0Reserve);
    const token1ReserveFormatted = ethers.formatEther(token1Reserve / USDCDecimal);
    return { token0ReserveFormatted, token1ReserveFormatted };
  }
};

const getPairAddress = async (routerContract, factoryAbi, token0, token1) => {
  try {
    const factoryAddress = await routerContract.factory();
    const factoryContract = new ethers.Contract(factoryAddress, factoryAbi, provider);
    const pairAddress = await factoryContract.getPair(token0, token1);
    return pairAddress;
  } catch (error) {
    console.log('error', error);
  }
};


compareAndTrade();
