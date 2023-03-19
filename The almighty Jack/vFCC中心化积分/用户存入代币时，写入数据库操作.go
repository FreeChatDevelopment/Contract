package main

import (
    "context"
    "database/sql"
    "fmt"
    "math/big"

    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
    _ "github.com/go-sql-driver/mysql"
)

func main() {
    // 连接以太坊节点
    client, err := ethclient.Dial("https://mainnet.infura.io/v3/<your-project-id>")
    if err != nil {
        fmt.Println("Failed to connect to the Ethereum network:", err)
        return
    }

    // 合约地址和用户地址
    contractAddress := common.HexToAddress("<contract-address>")
    userAddress := common.HexToAddress("<user-address>")

    // 获取存款Nonce值
    var nonce *big.Int
    if err := client.CallContext(context.Background(), &nonce, "eth_getTransactionCount", userAddress, "latest"); err != nil {
        fmt.Println("Failed to get transaction count:", err)
        return
    }

    // 从合约中获取存款金额
    var depositAmount *big.Int
    if err := client.CallContext(context.Background(), &depositAmount, "eth_call", map[string]string{
        "to":   contractAddress.Hex(),
        "data": fmt.Sprintf("0x3b16c1de%064x%064x", userAddress, nonce),
    }, "latest"); err != nil {
        fmt.Println("Failed to get deposit amount:", err)
        return
    }

    // 连接MySQL数据库
    db, err := sql.Open("mysql", "user:password@tcp(localhost:3306)/mydb")
    if err != nil {
        fmt.Println("Failed to connect to the MySQL database:", err)
        return
    }
    defer db.Close()

    // 插入存款记录
    _, err = db.Exec("INSERT INTO deposits (user_address, deposit_amount) VALUES (?, ?)", userAddress.Hex(), depositAmount.String())
    if err != nil {
        fmt.Println("Failed to insert deposit record:", err)
        return
    }

    fmt.Printf("User %s has deposited %s tokens\n", userAddress.Hex(), depositAmount.String())
}

//在这个示例中，我们连接到以太坊网络和MySQL数据库。然后，我们指定了合约地址和用户地址，使用以太坊JSON-RPC API获取用户的存款Nonce值，然后使用合约的ABI编码调用合约函数来获取存款金额。接着，我们连接到MySQL数据库，并将存款记录插入到数据库中。最后，我们将存款金额打印到控制台。
//请注意，您需要将<your-project-id>替换为您自己的Infura项目ID，并将<contract-address>和<user-address>替换为您要查询的合约地址和用户地址。另外，您需要将连接字符串"user:password@tcp(localhost:3306)/mydb"替换为您自己的MySQL数据库连接字符串。还要确保在数据库中创建了名为“deposits”的表，该表包含列"user_address"和"deposit_amount"。