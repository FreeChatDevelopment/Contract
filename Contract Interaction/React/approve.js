const Web3 = require("web3");
const web3 = new Web3("https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID");

const userAddress = "0xYourUserAddress"; // 用户地址
const privateKey = "0xYourPrivateKey"; // 用户私钥

const tokenContractAddress = "0xYourTokenContractAddress"; // ERC20代币合约地址
const myContractAddress = "0x4ef5c2a6a8c080279dff08391fdc9144df005b37"; // MySecuredContractWithAdminTransferRecord合约地址

const erc20Abi = [/*...*/]; // ERC20代币ABI数组，请从对应的代币项目中获取

const tokenContract = new web3.eth.Contract(erc20Abi, tokenContractAddress);

const approveAmount = web3.utils.toWei("100", "ether"); // 将要授权的代币数量，这里以100代币为例，需要根据实际情况修改

const approveData = tokenContract.methods.approve(myContractAddress, approveAmount).encodeABI();

const nonce = await web3.eth.getTransactionCount(userAddress);

const tx = {
  from: userAddress,
  to: tokenContractAddress,
  data: approveData,
  nonce: nonce,
  gas: 100000, // 估算gas，实际gas需要根据实际情况进行调整
  gasPrice: web3.utils.toWei("20", "gwei") // 设置gas价格，根据实际网络状况进行调整
};

const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);

const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
console.log("Transaction Receipt:", receipt);
