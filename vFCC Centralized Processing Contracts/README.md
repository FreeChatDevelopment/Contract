这份智能合约是一个中心化积分系统，名为 Freechat vFCC。它允许用户在合约中存入一定数量的 ERC20 代币，并允许管理员在合约中转移代币到指定地址。

以下是合约中的函数和调用参数的详细介绍：

### deposit(uint256 amount)

功能：允许用户在合约中存入指定数量的 ERC20 代币

参数：amount - 存款金额

### adminTransfer(address to, uint256 amount)

功能：允许管理员从合约中转移指定数量的 ERC20 代币到指定地址

参数：to - 接收地址，amount - 转账金额

### getDepositAmount(address user, uint256 nonce)

功能：根据用户地址和Nonce值获取存款金额

### 参数：user - 用户地址，nonce - 存款Nonce值

getDepositNonce(address user)

功能：获取用户的存款Nonce值

### 参数：user - 用户地址

getAdminTransferAmount(address admin, uint256 nonce)

功能：根据管理员地址和Nonce值获取管理员转账金额

参数：admin - 管理员地址，nonce - 转账Nonce值

### getAdminTransferNonce(address admin)

功能：获取管理员的转账Nonce值

参数：admin - 管理员地址

### getRecipient(address admin, uint256 nonce)

功能：根据管理员地址和Nonce值获取接收者地址

参数：admin - 管理员地址，nonce - 转账Nonce值

### getBalance()

功能：获取合约中的 ERC20 代币余额

参数：无

### getAllowance()

功能：获取合约被授权的代币数量

参数：无

### withdraw(uint256 amount)

功能：仅限管理员角色调用，从合约中提取指定数量的 ERC20 代币到管理员地址

参数：amount - 提取金额

### revokeAdminRole(address account)

功能：仅限默认管理员角色调用，撤销指定账户的管理员角色

参数：account - 要撤销角色的账户地址

### grantAdminRole(address account)

功能：仅限默认管理员角色调用，授予指定账户管理员角色

参数：account - 要授予角色的账户地址

### renounceAdminRole()

功能：放弃管理员角色

参数：无

### 管理员转账

函数名：adminTransfer

调用参数：address to, uint256 amount

功能描述：管理员向指定地址转移代币，需要具有ADMIN_ROLE权限。

### 获取存款记录

函数名：getDepositAmount, getDepositNonce

调用参数：address user, uint256 nonce

功能描述：根据用户地址和Nonce值获取存款金额及Nonce值。

### 获取管理员转账记录

函数名：getAdminTransferAmount, getAdminTransferNonce, getRecipient

调用参数：address admin, uint256 nonce

功能描述：根据管理员地址和Nonce值获取管理员转账金额、Nonce值及接收者地址。

### 获取代币余额和授权额度

函数名：getBalance, getAllowance

调用参数：无

功能描述：分别获取合约中的代币余额和调用者对合约的代币授权额度。

### 提现代币

函数名：withdraw

调用参数：uint256 amount

功能描述：仅限管理员角色调用，从合约中提现指定数量的代币到调用者地址。

### 撤销和授予管理员角色

函数名：revokeAdminRole, grantAdminRole

调用参数：address account

功能描述：仅限默认管理员角色调用，分别撤销和授予指定地址的管理员角色。

### 放弃管理员角色

函数名：renounceAdminRole

调用参数：无

功能描述：调用者放弃自己的管理员角色。

getRecipient(address admin, uint256 nonce) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address)：根据管理员地址和Nonce值获取对应管理员转账记录的接收者地址。参数为管理员地址和对应的Nonce值。该函数返回对应管理员转账记录的接收者地址。

getBalance() external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256)：获取合约中的代币余额。该函数仅限管理员角色调用。该函数返回合约中的代币余额。

getAllowance() external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256)：获取合约的授权额度。该函数仅限管理员角色调用。该函数返回合约的授权额度。

withdraw(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant：提现函数，仅限管理员角色调用。参数为提现的代币数量。该函数检查合约中的代币余额是否足够，如果足够则调用ERC20代币合约的方法，将代币从合约地址转移到调用者地址。

revokeAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE)：撤销管理员角色。参数为要撤销的管理员地址。该函数仅限管理员角色调用。该函数将指定地址的管理员角色撤销。

grantAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE)：授予管理员角色。参数为要授予管理员角色的地址。该函数仅限管理员角色调用。该函数将指定地址授予管理员角色。

renounceAdminRole() external：放弃管理员角色。该函数将当前调用者的管理员角色放弃。


### 合约介绍

合约功能如下：

存款：用户可以将ERC20代币存入到合约中。

管理员转账：只有管理员角色可以在用户之间进行代币转账。

查询记录：任何人可以查询用户的存款记录和管理员转账记录。

提现：只有管理员角色可以从合约中提取ERC20代币。

管理管理员角色：可以添加、删除或撤销管理员角色。

### 合约测试方法

部署合约：在部署合约时，将ERC20代币合约地址作为构造函数参数传入。

授予和撤销管理员角色：使用grantAdminRole()和revokeAdminRole()函数添加或删除管理员角色。

用户存款：调用deposit()函数，传入要存入的代币数量。

管理员转账：调用adminTransfer()函数，传入接收者地址和要转账的代币数量。

查询记录：使用getDepositAmount()、getDepositNonce()、getAdminTransferAmount()、getAdminTransferNonce()和getRecipient()函数查询存款和转账记录。

提现：调用withdraw()函数，传入要提取的代币数量。

查询余额：使用getBalance()和getAllowance()函数查询合约中的代币余额和授权额度。