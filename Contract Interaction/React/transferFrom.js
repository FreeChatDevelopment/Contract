// 导入依赖
const { ethers } = require('ethers');

// ERC20代币合约ABI
const erc20Abi = [
  "function approve(address spender, uint256 value) public returns (bool)",
  "function transferFrom(address from, address to, uint256 value) public returns (bool)",
  "function allowance(address owner, address spender) public view returns (uint256)",
];

// 使用你的私钥和网络提供程序
const privateKey = 'your-private-key';
const provider = new ethers.providers.JsonRpcProvider('your-rpc-provider-url');
const wallet = new ethers.Wallet(privateKey, provider);

// 设置合约地址和交易的相关地址
const tokenContractAddress = 'your-token-contract-address';
const fromAddress = 'address-to-transfer-from';
const toAddress = 'address-to-transfer-to';
const amount = ethers.utils.parseUnits('10', 18); // 10代币（假设代币有18位小数）

// 创建ERC20代币合约实例
const tokenContract = new ethers.Contract(tokenContractAddress, erc20Abi, wallet);

async function transferFrom() {
  // 首先，批准合约调用者从`fromAddress`转移`amount`数量的代币
  const approveTx = await tokenContract.approve(wallet.address, amount);
  await approveTx.wait();

  // 确认授权额度
  const allowance = await tokenContract.allowance(fromAddress, wallet.address);
  console.log('Allowance:', ethers.utils.formatUnits(allowance, 18));

  // 如果授权额度充足，执行transferFrom操作
  if (allowance.gte(amount)) {
    const transferFromTx = await tokenContract.transferFrom(fromAddress, toAddress, amount);
    const receipt = await transferFromTx.wait();
    console.log('TransferFrom successful, transaction hash:', receipt.transactionHash);
  } else {
    console.log('Insufficient allowance, please approve a higher amount.');
  }
}

transferFrom().catch(console.error);
