// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入依赖库
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// 合约：MySecuredContractWithAdminTransferRecord
// 这个合约继承了AccessControl和ReentrancyGuard。
contract MySecuredContractWithAdminTransferRecord is AccessControl, ReentrancyGuard {
// 使用SafeMath库来处理uint256类型的数学运算
using SafeMath for uint256;
// 使用SafeERC20库来处理IERC20接口的方法调用
using SafeERC20 for IERC20;
// 定义_freechatCoin变量来表示ERC20代币
IERC20 private _freechatCoin;
// 定义ADMIN_ROLE常量，表示管理员角色
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
// 定义存款记录结构体
struct Record {
    uint256 depositAmount;
    uint256 depositNonce;
    uint256 adminTransferAmount;
    uint256 adminTransferNonce;
    address recipient;
    uint256 timestamp;
}

// 定义一个映射，将地址映射到存款记录数组
mapping(address => Record[]) private _records;

// 定义常量RECORDS_LIMIT，限制记录数量
uint256 private constant RECORDS_LIMIT = 100;

event Deposit(address indexed user, uint256 amount, uint256 nonce);
event AdminTransfer(address indexed from, address indexed to, uint256 amount, uint256 nonce);

// 构造函数，初始化_freechatCoin变量和管理员角色
constructor(IERC20 freechatCoin) {
    _freechatCoin = freechatCoin;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
}

// 存款函数
function deposit(uint256 amount) external {
    // 检查存款金额是否大于0
    require(amount > 0, "Deposit amount must be greater than 0");

    // 生成随机Nonce值
    uint256 currentNonce = generateRandomNonce(msg.sender);

    // 如果记录数组达到限制，则删除最早的记录
    if (_records[msg.sender].length >= RECORDS_LIMIT) {
        delete _records[msg.sender][0];
        for (uint256 i = 1; i < RECORDS_LIMIT; i++) {
            _records[msg.sender][i-1] = _records[msg.sender][i];
        }
        _records[msg.sender].pop();
    }

    // 在记录数组中添加新的存款记录
    _records[msg.sender].push(Record(amount, currentNonce, 0, 0, address(0), block.timestamp));
    emit Deposit(msg.sender, amount, currentNonce);

    // 调用ERC20代币合约的方法，将代币从用户地址转移到合约地址
    _freechatCoin.safeApprove(address(this), amount);
    _freechatCoin.safeTransferFrom(msg.sender, address(this), amount);
}

// 管理员转账函数
function adminTransfer(address to, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant {
// 检查转账金额是否大于0
require(amount > 0, "Transfer amount must be greater than 0");
// 检查接收地址是否有效
require(to != address(0), "Invalid recipient address");

    // 生成随机Nonce值
    uint256 currentNonce = generateRandomNonce(msg.sender);

    // 如果记录数组达到限制，则删除最早的记录
    if (_records[msg.sender].length >= RECORDS_LIMIT) {
        delete _records[msg.sender][0];
        for (uint256 i = 1; i < RECORDS_LIMIT; i++) {
            _records[msg.sender][i-1] = _records[msg.sender][i];
        }
        _records[msg.sender].pop();
    }

    // 在记录数组中添加新的管理员转账记录
    _records[msg.sender].push(Record(0, 0, amount, currentNonce, to, block.timestamp));

    // 检查合约中的代币余额是否足够
    require(_freechatCoin.balanceOf(address(this)) >= amount, "Insufficient balance in contract");

    // 调用ERC20代币合约的方法，将代币从合约地址转移到接收地址
    _freechatCoin.safeApprove(to, amount);
    emit AdminTransfer(msg.sender, to, amount, currentNonce);
}

// 根据用户地址和Nonce值获取存款金额
function getDepositAmount(address user, uint256 nonce) public view returns (uint256) {
    for (uint256 i = 0; i < _records[user].length; i++) {
        if (_records[user][i].depositNonce == nonce) {
            return _records[user][i].depositAmount;
        }
    }
    revert("Record not found");
}

// 获取用户的存款Nonce值
function getDepositNonce(address user) public view returns (uint256) {
    return _records[user].length;
}

// 根据管理员地址和Nonce值获取管理员转账金额
function getAdminTransferAmount(address admin, uint256 nonce) public view onlyRole(ADMIN_ROLE) returns (uint256) {
    for (uint256 i = 0; i < _records[admin].length; i++) {
        if (_records[admin][i].adminTransferNonce == nonce) {
            return _records[admin][i].adminTransferAmount;
        }
    }
    revert("Record not found");
}

// 获取管理员的转账Nonce值
function getAdminTransferNonce(address admin) public view onlyRole(ADMIN_ROLE) returns (uint256) {
    return _records[admin].length;
}

// 根据管理员地址和Nonce值获取接收者地址
function getRecipient(address admin, uint256 nonce) public view onlyRole(ADMIN_ROLE) returns (address) {
    for (uint256 i = 0; i < _records[admin].length; i++) {
        if (_records[admin][i].adminTransferNonce == nonce) {
            return _records[admin][i].recipient;
        }
    }
    revert("Record not found");
}

// 获取合约中的代币余额
function getBalance() external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    return _freechatCoin.balanceOf(address(this));
}

// 获取合约的授权额度
function getAllowance() external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
return _freechatCoin.allowance(msg.sender, address(this));
}

// 提现函数，仅限管理员角色调用
function withdraw(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    // 检查合约中的代币余额是否足够
    require(amount <= _freechatCoin.balanceOf(address(this)), "Insufficient balance in contract");

    // 调用ERC20代币合约的方法，将代币从合约地址转移到调用者地址
    _freechatCoin.safeApprove(address(this), amount);
    _freechatCoin.safeTransfer(msg.sender, amount);
}

// 紧急提现函数，仅限管理员角色调用
function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    // 获取合约中的全部代币余额
    uint256 amount = _freechatCoin.balanceOf(address(this));

    // 调用ERC20代币合约的方法，将代币从合约地址转移到调用者地址
    _freechatCoin.safeApprove(address(this), amount);
    _freechatCoin.safeTransfer(msg.sender, amount);
}

// 撤销管理员角色
function revokeAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(ADMIN_ROLE, account);
}

// 授予管理员角色
function grantAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(ADMIN_ROLE, account);
}

// 放弃管理员角色
function renounceAdminRole() external {
    renounceRole(ADMIN_ROLE, msg.sender);
}

// 生成随机Nonce值的内部方法
function generateRandomNonce(address user) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), user, block.timestamp)));
}


