## 这是一个名为 "Freechat vFCC中心化积分系统" 的智能合约，其功能如下：

只有被授予 "ADMIN_ROLE" 的角色才能进行 "adminTransfer" 操作，该操作允许管理员向指定地址转移代币。

"deposit" 函数允许用户将代币存入合约中，存入的代币数量不能为 0。

"withdraw" 函数允许管理员从合约中提取代币，提取的代币数量不能超过合约中存储的余额。

"emergencyWithdraw" 函数允许管理员从合约中提取所有的代币。

"getDepositAmount" 函数允许用户获取指定 nonce 的存款金额。

"getDepositNonce" 函数允许用户获取他们存入合约的存款记录数。

"getAdminTransferAmount" 函数允许管理员获取指定 nonce 的转账金额。

"getAdminTransferNonce" 函数允许管理员获取他们进行的转账记录数。

"getRecipient" 函数允许管理员获取指定 nonce 的转账接收地址。

"getBalance" 函数允许管理员获取合约中存储的代币余额。

"getAllowance" 函数允许管理员获取合约被授权的代币数量。

"revokeAdminRole" 和 "grantAdminRole" 函数允许管理员对其他帐户授予或撤销 "ADMIN_ROLE" 角色。

"renounceAdminRole" 函数允许管理员自己放弃 "ADMIN_ROLE" 角色。

该合约使用了 OpenZeppelin 的 AccessControl 和 ReentrancyGuard 库以增加安全性。


## vFCC代码参数的描述

### 引用的 Solidity 库和协议

@openzeppelin/contracts/token/ERC20/IERC20.sol：用于 ERC20 token 的接口定义

@openzeppelin/contracts/access/AccessControl.sol：用于管理合约角色和权限的合约

@openzeppelin/contracts/utils/math/SafeMath.sol：用于执行安全数学运算的库

@openzeppelin/contracts/security/ReentrancyGuard.sol：用于防止重入攻击的合约

### 合约中的主要数据结构和变量

IERC20 private _freechatCoin：用于管理 ERC20 token 的实例

bytes32 public constant ADMIN_ROLE：用于定义管理员角色的常量

struct Record：用于存储存款和管理员转账记录的结构体

mapping(address => Record[]) private _records：用于存储用户的存款和管理员转账记录的映射

uint256 private constant RECORDS_LIMIT：用于限制存储记录数量的常量

### 合约中的主要事件

event Deposit：用于记录用户存款的事件

event AdminTransfer：用于记录管理员转账的事件

### 合约中的主要函数

deposit：用户存款函数，用于将用户的 ERC20 token 存入合约中，并记录存款记录

adminTransfer：管理员转账函数，用于将 ERC20 token 从合约中转账给指定地址，并记录管理员转账记录

getDepositAmount：获取用户指定存款记录的存款金额

getDepositNonce：获取用户存款记录数量

getAdminTransferAmount：获取指定管理员转账记录的转账金额

getAdminTransferNonce：获取管理员转账记录数量

getRecipient：获取指定管理员转账记录的接收地址

getBalance：获取合约当前的 ERC20 token 余额

getAllowance：获取合约当前授权可转账的 ERC20 token 数量

withdraw：管理员提现函数，用于将合约中的 ERC20 token 转账给合约所有者

emergencyWithdraw：管理员紧急提现函数，用于将合约中的所有 ERC20 token 转账给合约所有者

revokeAdminRole：取消管理员角色的函数，用于从指定账户中撤销管理员角色

grantAdminRole：授予管理员角色的函数，用于将管理员角色授予指定账户

renounceAdminRole：放弃管理员角色的函数，用于从当前调用者中移除管理员角色