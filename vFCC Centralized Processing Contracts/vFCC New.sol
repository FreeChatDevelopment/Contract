// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入依赖库
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// 合约：Freechat vFCC中心化积分系统
// 这个合约继承了AccessControl和ReentrancyGuard。
contract MySecuredContractWithAdminTransferRecord is
    AccessControl,
    ReentrancyGuard
{
    // 使用SafeMath库来处理uint256类型的数学运算
    using SafeMath for uint256;
    // 使用SafeERC20库来处理IERC20接口的方法调用
    using SafeERC20 for IERC20;
    // 定义_TokenContractAddress变量来表示ERC20代币
    IERC20 private _TokenContractAddress;
    // 定义ADMIN_ROLE常量，表示管理员角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // 定义一个修改器，确保只有记录所有者才能访问记录
modifier onlyRecordOwner(address user, uint256 nonce) {
    require(msg.sender == user || hasRole(ADMIN_ROLE, msg.sender), "unauthorized");
    require(_getRecord(user, nonce, RecordType.Deposit).nonce != 0, "record not found");
    _;
}
    // 定义记录类型枚举
    enum RecordType { Deposit, AdminTransfer }
    // 定义存款记录结构体
    struct Record {
    RecordType recordType;
    uint256 amount;
    uint256 nonce;
    address recipient;
    uint256 timestamp;
}

// 定义一个映射，将地址映射到存款记录数组
mapping(address => Record[]) private _records;
mapping(address => uint256) private _recordNonces;

// 定义记录限制变量
uint256 private _recordsLimit = 100;

    event Deposit(address indexed user, uint256 amount, uint256 nonce);
    event AdminTransfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 nonce
    );

    // 构造函数，初始化_TokenContractAddress变量和管理员角色
    constructor(IERC20 freechatCoin) {
        _TokenContractAddress = freechatCoin;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

 // 存款函数
function deposit(uint256 amount) external {
    // 检查存款金额是否大于0
    require(amount > 0, "deposit must > 0");
    uint256 currentNonce = _recordNonces[msg.sender];
    require(_records[msg.sender].length < _recordsLimit, "too many records");
    _records[msg.sender].push(Record(
        RecordType.Deposit,
        amount,
        currentNonce,
        address(0),
        block.timestamp
    ));
    emit Deposit(msg.sender, amount, currentNonce);
    _recordNonces[msg.sender] = _recordNonces[msg.sender].add(1);
        // 判断记录数量是否超过限制
    if (_records[msg.sender].length >= _recordsLimit) {
        // 覆盖最旧的记录
        _records[msg.sender][0] = Record(
            RecordType.Deposit,
            amount,
            currentNonce,
            address(0),
            block.timestamp
        );
    } else {
        // 添加新记录
        _records[msg.sender].push(Record(
            RecordType.Deposit,
            amount,
            currentNonce,
            address(0),
            block.timestamp
        ));
    }
    // 调用ERC20代币合约的方法，将代币从用户地址转移到合约地址
    _TokenContractAddress.safeTransferFrom(
        msg.sender,
        address(this),
        amount
    );
}

// 管理员转账函数
function adminTransfer(
    address to,
    uint256 amount
) external onlyRole(ADMIN_ROLE) nonReentrant {
    // 检查转账金额是否大于0
    require(amount > 0, "amount must > 0");
    // 检查接收地址是否有效
    require(to != address(0), "invalid address");
    uint256 currentNonce = _recordNonces[msg.sender];
    require(_records[msg.sender].length < _recordsLimit, "too many records");
    _records[msg.sender].push(Record(
        RecordType.AdminTransfer,
        amount,
        currentNonce,
        to,
        block.timestamp
    ));
    emit AdminTransfer(msg.sender, to, amount, currentNonce);
    _recordNonces[msg.sender] = _recordNonces[msg.sender].add(1);
    // 判断记录数量是否超过限制
    if (_records[msg.sender].length >= _recordsLimit) {
        // 覆盖最旧的记录
        _records[msg.sender][0] = Record(
            RecordType.AdminTransfer,
            amount,
            currentNonce,
            to,
            block.timestamp
        );
    } else {
        // 添加新记录
        _records[msg.sender].push(Record(
            RecordType.AdminTransfer,
            amount,
            currentNonce,
            to,
            block.timestamp
        ));
    }

    // 检查合约中的代币余额是否足够
    require(
        _TokenContractAddress.balanceOf(address(this)) >= amount,
        "balance not enough"
    );

    // 调用ERC20代币合约的方法，将代币从合约地址转移到接收地址
    _TokenContractAddress.safeTransfer(to, amount);
}

// 根据用户地址和Nonce值获取存款金额
function getDepositAmount(
    address user,
    uint256 nonce
) public view onlyRecordOwner(user, nonce) returns (uint256) {
    return _getRecord(user, nonce, RecordType.Deposit).amount;
}

// 根据管理员地址和Nonce值获取管理员转账金额
function getAdminTransferAmount(
    address admin,
    uint256 nonce
) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    return _getRecord(admin, nonce, RecordType.AdminTransfer).amount;
}

// 获取记录
function _getRecord(address user, uint256 nonce, RecordType recordType) private view returns (Record storage) {
require(_records[user].length > 0, "no records found");
for (uint256 i = 0; i < _records[user].length; i++) {
Record storage record = _records[user][i];
if (record.nonce == nonce && record.recordType == recordType) {
return record;
}
}
revert("record not found");
}

 // 获取用户的存款Nonce值
function getDepositNonce(address user) public view returns (uint256) {
require(msg.sender == user || hasRole(ADMIN_ROLE, msg.sender), "unauthorized");
return _recordNonces[user];
}

 // 获取管理员的转账Nonce值
function getAdminTransferNonce(
address admin
) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
return _recordNonces[admin];
}

// 根据管理员地址和Nonce值获取接收者地址
function getRecipient(
address admin,
uint256 nonce
) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
return _getRecord(admin, nonce, RecordType.AdminTransfer).recipient;
}

// 获取合约中的代币余额
function getBalance()
external
view
onlyRole(DEFAULT_ADMIN_ROLE)
returns (uint256)
{
return _TokenContractAddress.balanceOf(address(this));
}

// 获取合约的授权额度
function getAllowance(address account)
external
view
onlyRole(DEFAULT_ADMIN_ROLE)
returns (uint256)
{
return _TokenContractAddress.allowance(account, address(this));
}

// 提现函数，仅限管理员角色调用
function withdraw(
uint256 amount
) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
// 检查合约中的代币余额是否足够
require(
amount <= _TokenContractAddress.balanceOf(address(this)),
"balance not enough"
);
// 调用ERC20代币合约的方法，将代币从合约地址转移到调用者地址
_TokenContractAddress.safeTransfer(msg.sender, amount);
}

// 撤销管理员角色
function revokeAdminRole(
address account
) external onlyRole(DEFAULT_ADMIN_ROLE) {
revokeRole(ADMIN_ROLE, account);
}

// 授予管理员角色
function grantAdminRole(
address account
) external onlyRole(DEFAULT_ADMIN_ROLE) {
grantRole(ADMIN_ROLE, account);
}

// 放弃管理员角色
function renounceAdminRole() external {
renounceRole(ADMIN_ROLE, msg.sender);
}
}
