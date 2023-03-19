func transferFromToken(web3Instance: web3, fromAddress: String, contractAddress: String, spenderAddress: String, toAddress: String, amount: String) {
    do {
        // 创建交易发起者地址对象
        let from = EthereumAddress(fromAddress)!
        // 创建合约地址对象
        let contract = EthereumAddress(contractAddress)!
        // 创建发送者地址对象
        let spender = EthereumAddress(spenderAddress)!
        // 创建接收者地址对象
        let to = EthereumAddress(toAddress)!
        // 将字符串形式的金额转换为BigUInt类型
        let value = BigUInt(amount)!

        // 创建交易参数
        var options = TransactionOptions.defaultOptions
        options.from = spender

        // 获取ERC20合约实例
        let erc20Contract = web3Instance.contract(Web3.Utils.erc20ABI, at: contract, abiVersion: 2)!

        // 创建transferFrom交易
        let transaction = erc20Contract.write(
            "transferFrom",
            parameters: [from, to, value] as [AnyObject],
            extraData: Data(),
            transactionOptions: options
        )!

        // 估算交易的Gas成本
        options.gasPrice = .automatic
        options.gasLimit = .automatic
        let gasEstimateResult = try transaction.estimateGas(transactionOptions: options)
        options.gasLimit = gasEstimateResult

        // 对交易进行签名并发送
        // 注意：请确保已解锁您的钱包并在发送交易前设置好交易选项
        let result = try transaction.send(password: "YourPassword")
        print("Transaction sent successfully, transaction hash: \(result.hash)")
    } catch {
        print("Error: \(error)")
    }
}
