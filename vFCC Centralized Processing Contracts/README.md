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