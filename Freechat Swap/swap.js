// 导入依赖
const { ethers } = require('ethers');
const { Token, WETH } = require('@uniswap/sdk-core');
const { Pool, Trade, Route, TokenAmount, TradeType, Percent } = require('@uniswap/v3-sdk');

// 钱包和RPC提供者设置
const provider = new ethers.providers.JsonRpcProvider('https://mainnet.infura.io/v3/YOUR-INFURA-PROJECT-ID');
const walletPrivateKey = 'YOUR-WALLET-PRIVATE-KEY';
const wallet = new ethers.Wallet(walletPrivateKey, provider);

// 全局变量
let extraFeeAmount;
let gasPrice;



// 代币合约地址
const tokenAAddress = '0x...'; // 代币A的合约地址
const tokenBAddress = '0x...'; // 代币B的合约地址

// Uniswap V3合约地址
const uniswapV3RouterAddress = '0xE592427A0AEce92De3Edee1F18E0157C05861564';

// 初始化代币
const tokenA = new Token(1, tokenAAddress, 18, 'TOKEN_A', 'Token A');
const tokenB = new Token(1, tokenBAddress, 18, 'TOKEN_B', 'Token B');

// 设置手续费比例
const feeRatio = new Percent('3', '10000'); // 0.03%

async function getPoolInfo() {
  // 获取Token A和Token B的汇率
  const amountIn = '1000000000000000000'; // 1 Token A
  const amountOut = '1000000000000000000'; // 1 Token B

  // 构建池
  const pool = new Pool(
    tokenA,
    tokenB,
    3000, // Uniswap V3 中的手续费层（0.3%）
    amountIn,
    amountOut
  );

  return pool;
}

async function executeSwap(tokenInAmount, tokenOutAmount, slippageTolerance) {
  const pool = await getPoolInfo();
  const route = new Route([pool], tokenA, tokenB);

  // 计算兑换路径和兑换数据
  const trade = new Trade(
    route,
    new TokenAmount(tokenA, tokenInAmount),
    TradeType.EXACT_INPUT
  );

    // 设置滑点容忍度
    const slippage = new Percent(slippageTolerance, '10000'); // 示例：50 -> 0.5%

    // 计算最小输出金额
    const minAmountOut = trade.minimumAmountOut(slippage).raw;
  
    // 获取交易期限（Unix时间戳）
    const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20分钟内有效
  
    // 生成交易数据
    const swapParams = [
      trade.inputAmount.raw.toString(),
      minAmountOut.toString(),
      trade.route.path.map(token => token.address),
      wallet.address,
      deadline,
    ];

// 计算额外的手续费（基于Uniswap手续费的50%）
const extraFeeRatio = new Percent('50', '100');
const uniswapFeeAmount = trade.executionPrice.multiply(trade.inputAmount.raw);
extraFeeAmount = uniswapFeeAmount.multiply(extraFeeRatio).toFixed(0);

  // 设置交易选项
  gasPrice = await provider.getGasPrice();
  const options = {
    gasLimit: 250000,
    gasPrice: gasPrice,
    value: ethers.BigNumber.from(trade.inputAmount.raw.toString()).add(extraFeeAmount),
  };

  
    // 执行交易
    const uniswapV3Router = new ethers.Contract(
      uniswapV3RouterAddress,
      [
        'function exactInputSingle((address,address,uint24,address,uint256,uint256,uint160,uint128,uint256))',
      ],
      wallet
    );
  
    const tx = await uniswapV3Router.exactInputSingle(
      {
        tokenIn: tokenA.address,
        tokenOut: tokenB.address,
        fee: 3000,
        recipient: wallet.address,
        deadline: deadline,
        amountIn: trade.inputAmount.raw.toString(),
        amountOutMinimum: minAmountOut.toString(),
        sqrtPriceLimitX96: 0,
      },
      options
    );
  
    console.log('Transaction sent:', tx.hash);
    const receipt = await tx.wait();
    console.log('Transaction confirmed:', receipt.transactionHash);
  }
  
  // 调用executeSwap函数进行兑换
  executeSwap('1000000000000000000', '1000000000000000000', 50)
    .then(() => console.log('Swap executed successfully'))
    .catch(error => console.error('Error:', error));
  
// 指定收款地址
const feeRecipient = '0x...';

async function sendExtraFee() {
    const tx = await wallet.sendTransaction({
      to: feeRecipient,
      value: extraFeeAmount,
      gasPrice: gasPrice,
    });
  
    console.log('Extra fee transaction sent:', tx.hash);
    const receipt = await tx.wait();
    console.log('Extra fee transaction confirmed:', receipt.transactionHash);
  }

// 在交易执行后发送额外手续费
executeSwap('1000000000000000000', '1000000000000000000', 50)
  .then(() => {
    console.log('Swap executed successfully');
    return sendExtraFee();
  })
  .then(() => console.log('Extra fee sent successfully'))
  .catch(error => console.error('Error:', error));

  