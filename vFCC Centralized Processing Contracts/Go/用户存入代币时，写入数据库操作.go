package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	_ "github.com/go-sql-driver/mysql"

	mycontract "path/to/MySecuredContractWithAdminTransferRecord" // 导入Solidity合约生成的Go绑定包
)

func main() {
	// 连接以太坊客户端
	client, err := ethclient.Dial("https://mainnet.infura.io/v3/<your-project-id>")
	if err != nil {
		panic(err)
	}

	// 数据库连接信息
	db, err := sql.Open("mysql", "<username>:<password>@tcp(<host>:<port>)/<database-name>")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	// 合约地址
	contractAddress := common.HexToAddress("<your-contract-address>")

	// 创建MySecuredContractWithAdminTransferRecord合约实例
	instance, err := mycontract.NewMySecuredContractWithAdminTransferRecord(contractAddress, client)
	if err != nil {
		panic(err)
	}

	// 订阅Deposit事件
	logs := make(chan *mycontract.MySecuredContractWithAdminTransferRecordDeposit)
	sub, err := instance.WatchDeposit(nil, logs)
	if err != nil {
		panic(err)
	}
	defer sub.Unsubscribe()

	// 循环监听事件
	for {
		select {
		case err := <-sub.Err():
			log.Fatal(err)
		case event := <-logs:
			fmt.Printf("Deposit event: user=%s, amount=%s\n", event.User.String(), event.Amount.String())

			// 将数据写入数据库
			_, err := db.Exec("INSERT INTO deposit (user, amount) VALUES (?, ?)", event.User.String(), event.Amount.String())
			if err != nil {
				panic(err)
			}
		}
	}
}


这份代码订阅了合约的Deposit事件，并在事件触发时将用户地址和存款金额写入了MySQL数据库的deposit表中。你需要替换示例代码中的数据库连接信息和表名，并根据自己的需求进行调整。