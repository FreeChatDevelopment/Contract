const { ethers } = require("ethers");
const TokenABI = require("./TokenName"); // 导入TokenName.js文件中的ABI

// 连接到Ethereum网络（这里使用Infura提供的主网节点）
const provider = new ethers.providers.JsonRpcProvider("https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID");

// 用户私钥
const privateKey = "0xYourPrivateKey";

// 创建一个Wallet实例
const wallet = new ethers.Wallet(privateKey, provider);

// ERC20代币合约地址
const tokenContractAddress = "0xYourTokenContractAddress";

// 接收者地址
const recipient = "0xRecipientAddress";

// 要转账的代币数量
const transferAmount = ethers.utils.parseUnits("10", "ether"); // 这里以10代币为例，需要根据实际情况修改

// 创建一个代币合约实例，将 erc20Abi 更改为从文件导入的 TokenABI
const tokenContract = new ethers.Contract(tokenContractAddress, TokenABI, wallet);

async function transferERC20Tokens() {
  try {
    // 调用ERC20合约的transfer方法
    const tx = await tokenContract.transfer(recipient, transferAmount);
  
    // 等待交易被确认
    const receipt = await tx.wait();
  
    console.log("Transaction Receipt:", receipt);
  } catch (error) {
    console.error("Error:", error);
  }
}

transferERC20Tokens();