合约名：TokenStaking

功能介绍：

TokenStaking是一个代币质押合约，支持用户将代币锁定在合约中获取奖励，并可以随时提取已锁定的代币。

函数说明：

stake(uint amount)
用户将指定数量的代币锁定在合约中。

参数：

amount: 要锁定的代币数量。


withdraw(uint amount)
用户提取从合约中提取一定数量被锁定的代币。

参数：

amount: 要提取的代币数量。

addToBlacklist(address account)
将指定用户加入黑名单，阻止其进行质押和提现操作。

参数：

account: 要加入黑名单的用户地址。

removeFromBlacklist(address account)
将指定用户从黑名单中移除，允许其进行质押和提现操作。

参数：

account: 要移除黑名单的用户地址。

setTokenAddress(address newTokenAddress)
设置质押的代币地址。

参数：

newTokenAddress: 新的代币地址。

setMaxStakingAmount(uint newMaxStakingAmount)
设置最大质押限制。

参数：

newMaxStakingAmount: 新的最大质押限制。

pause()
暂停合约操作，阻止质押和提现操作。

unpause()
恢复合约操作，允许质押和提现操作。

getTotalStakedTokens()
获取当前合约中总的锁定代币数量。

getStakedTokens(address account)
获取指定用户在合约中锁定的代币数量。

参数：
account: 用户地址。


