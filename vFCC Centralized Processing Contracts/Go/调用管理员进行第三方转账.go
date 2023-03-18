package main

import (
    "context"
    "fmt"
    "math/big"

    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/accounts/abi/bind"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/crypto"
    "github.com/ethereum/go-ethereum/ethclient"
)

import mycontract "path/to/MySecuredContractWithAdminTransferRecord"
import token "path/to/ERC20Token" // 导入代币合约的ABI

func main() {
    // 连接以太坊客户端
    client, err := ethclient.Dial("https://mainnet.infura.io/v3/<your-project-id>")
    if err != nil {
        panic(err)
    }

    // 账户私钥和地址
    privateKey, err := crypto.HexToECDSA("<your-private-key>")
    if err != nil {
        panic(err)
    }
    publicKey := privateKey.Public()
    publicKeyECDSA, ok := publicKey.(*crypto.PublicKey)
    if !ok {
        panic("error casting public key to ECDSA")
    }
    fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

    // 合约地址
    contractAddress := common.HexToAddress("<your-contract-address>")

    // 获取管理员账户的nonce值
    nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
    if err != nil {
        panic(err)
    }

    // 创建管理员账户的签名私钥
    auth := bind.NewKeyedTransactor(privateKey)
    auth.Nonce = big.NewInt(int64(nonce))
    auth.Value = big.NewInt(0)
    auth.GasLimit = uint64(300000) // 指定gas上限
    auth.GasPrice = big.NewInt(1000000000) // 指定gas价格

    // 创建MySecuredContractWithAdminTransferRecord合约实例
    instance, err := mycontract.NewMySecuredContractWithAdminTransferRecord(contractAddress, client)
    if err != nil {
        panic(err)
    }

    // ERC20代币合约地址
    tokenAddress := common.HexToAddress("<your-token-address>")
    // 创建代币合约实例
    tokenInstance, err := token.NewToken(tokenAddress, client)
    if err != nil {
        panic(err)
    }

    // 转账目标地址
    toAddress := common.HexToAddress("<recipient-address>")

    // 转账金额
    amount := big.NewInt(1000000000000000000) // 1个代币，单位为Wei

    // 构造调用代币合约转账函数的交易数据
    tokenAbi, err := abi.JSON(strings.NewReader(token.TokenABI))
    if err != nil {
        panic(err)
    }
    data, err := tokenAbi.Pack("transfer", toAddress, amount)
    if err != nil {
        panic(err)
    }

    // 执行代币转账
    tx, err := tokenInstance
