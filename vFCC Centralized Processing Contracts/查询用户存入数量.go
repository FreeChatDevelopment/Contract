package main

import (
    "fmt"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
    mycontract "path/to/contract" // 替换成你的合约代码路径
)

func main() {
    client, err := ethclient.Dial("https://mainnet.infura.io/v3/your-project-id") // 替换成你的Infura项目ID
    if err != nil {
        panic(err)
    }

    contractAddress := common.HexToAddress("0x123...") // 替换成你的合约地址
    instance, err := mycontract.NewMySecuredContractWithAdminTransferRecord(contractAddress, client)
    if err != nil {
        panic(err)
    }

    userAddress := common.HexToAddress("0x456...") // 替换成你要查询的用户地址
    depositAmount, err := instance.GetDepositAmount(nil, userAddress)
    if err != nil {
        panic(err)
    }

    fmt.Printf("User %s deposit amount: %v", userAddress.String(), depositAmount)
}

需要替换的内容有：

path/to/contract：替换成你的合约代码路径。
https://mainnet.infura.io/v3/your-project-id：替换成你的Infura项目ID和网络，可以改为其他以太坊节点的地址。
0x123...：替换成你的合约地址。
0x456...：替换成你要查询的用户地址。