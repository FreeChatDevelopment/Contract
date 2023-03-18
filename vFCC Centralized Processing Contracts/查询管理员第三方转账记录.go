package main

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/core/types"
	"math/big"
	"time"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
)

// MySecuredContractWithAdminTransferRecord合约ABI
var mySecuredContractWithAdminTransferRecordABI = `ABI字符串`

// 合约地址
var contractAddress = common.HexToAddress("0x...")

func main() {
	// 连接以太坊节点
	client, err := ethclient.Dial("以太坊节点RPC地址")
	if err != nil {
		fmt.Printf("Failed to connect to the Ethereum network: %v\n", err)
		return
	}

	// 创建合约实例
	contractInstance, err := NewMySecuredContractWithAdminTransferRecord(contractAddress, client)
	if err != nil {
		fmt.Printf("Failed to create contract instance: %v\n", err)
		return
	}

	// 获取管理员账户
	adminPrivateKey, err := crypto.HexToECDSA("管理员账户私钥")
	if err != nil {
		fmt.Printf("Failed to get admin private key: %v\n", err)
		return
	}
	adminPublicKey := adminPrivateKey.Public()
	adminPublicKeyECDSA, ok := adminPublicKey.(*ecdsa.PublicKey)
	if !ok {
		fmt.Printf("Failed to cast admin public key to ECDSA: %v\n", err)
		return
	}
	adminAddress := crypto.PubkeyToAddress(*adminPublicKeyECDSA)

	// 获取管理员转账记录
	adminTransferFilterOpts := &bind.FilterOpts{
		Start:   0,
		End:     nil,
		Context: context.Background(),
	}
	adminTransferIterator, err := contractInstance.FilterAdminTransfer(adminTransferFilterOpts, []common.Address{adminAddress}, nil)
	if err != nil {
		fmt.Printf("Failed to create admin transfer iterator: %v\n", err)
		return
	}
	defer adminTransferIterator.Close()

	// 遍历管理员转账记录
	for adminTransferIterator.Next() {
		adminTransferEvent := adminTransferIterator.Event
		fmt.Printf("From: %s\n", adminTransferEvent.From.Hex())
		fmt.Printf("To: %s\n", adminTransferEvent.To.Hex())
		fmt.Printf("Amount: %s\n", adminTransferEvent.Amount.String())
		fmt.Printf("Nonce: %d\n", adminTransferEvent.Nonce)
	}
	if adminTransferIterator.Error() != nil {
		fmt.Printf("Failed to iterate admin transfer events: %v\n", adminTransferIterator.Error())
		return
	}
}


需要注意的是，其中的ABI字符串需要替换为实际的ABI，以太坊节点RPC地址和管理员账户私钥也需要替换为实际的值。另外，此代码示例使用的是Go Ethereum客户端库，需要提前安装。