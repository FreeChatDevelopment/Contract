// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MySecuredContract is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // 存储用户记录信息的结构体
    struct Record {
        uint256 amount;     // 存款金额
        address recipient;  // 转账目标地址（只用于管理员转账）
        uint256 timestamp;  // 存款时间戳
    }

    // 存储每个用户在不同代币上的存款记录
    mapping(address => mapping(address => Record[])) private _records;

    // 存储每个用户在不同代币上的存款记录数目
    mapping(address => mapping(address => uint256)) private _recordNonces;

    // 白名单列表
    mapping(address => bool) private _whitelistedTokens;
    address[] private _whitelistedTokenList;

    // 最大存款记录数目
    uint256 private constant _maxRecordsPerToken = 100;

    // 配置角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event AdminTransfer(address indexed from, address indexed to, address indexed token, uint256 amount);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyWhitelistedToken(address token) {
        require(isTokenWhitelisted(token), "token not whitelisted");
        _;
    }

    // 添加代币到白名单
    function addToWhitelist(address token) external onlyRole(ADMIN_ROLE) {
        require(!isTokenWhitelisted(token), "token already whitelisted");

        _whitelistedTokens[token] = true;
        _whitelistedTokenList.push(token);

        emit AddToWhitelist(token);
    }

    // 从白名单中移除代币
    function removeFromWhitelist(address token) external onlyRole(ADMIN_ROLE) {
        require(isTokenWhitelisted(token), "token not whitelisted");

        _whitelistedTokens[token] = false;

        for (uint256 i = 0; i < _whitelistedTokenList.length; i++) {
            if (_whitelistedTokenList[i] == token) {
                // 通过将要删除的元素和最后一个元素互换位置，然后删除最后一个元素，可以避免数组中的空洞
                _whitelistedTokenList[i] = _whitelistedTokenList[_whitelistedTokenList.length - 1];
                _whitelistedTokenList.pop();
                break;
            }
        }

        emit RemoveFromWhitelist(token);
    }
// 查询用户在某个代币上的某个记录的存款金额
function getDepositAmount(
address user,
address token,
uint256 nonce
) external view returns (uint256) {
// 验证用户和代币地址是否存在记录
require(_records[user][token].length > 0, "no deposit record found");
// 验证记录号是否有效
require(nonce < _records[user][token].length, "invalid record nonce");
// 返回指定记录的存款金额
return _records[user][token][nonce].amount;
}
// 查询用户在某个代币上的最新记录的编号
function getDepositNonce(address user, address token) external view returns (uint256) {
    // 返回用户在该代币上存款的记录数减1，即最新记录的编号
    return _recordNonces[user][token];
}

// 查询管理员在某个代币上的某个记录的收款人地址
function getAdminTransferRecipient(
    address admin,
    address token,
    uint256 nonce
) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
    // 验证管理员和代币地址是否存在记录
    require(_records[admin][token].length > 0, "no admin transfer record found");
    // 验证记录号是否有效
    require(nonce < _records[admin][token].length, "invalid record nonce");
    // 返回指定记录的收款人地址
    return _records[admin][token][nonce].recipient;
}

// 查询管理员在某个代币上的最新记录的编号
function getAdminTransferNonce(address admin, address token) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    // 返回管理员在该代币上的记录数减1，即最新记录的编号
    return _recordNonces[admin][token];
}

// 查询合约授权代币转移的额度
function getAllowance(address token, address account) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    // 返回合约对指定代币和账户的授权额度
    return IERC20(token).allowance(account, address(this));
}

// 从合约转移代币给管理员
function withdraw(address token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) onlyWhitelistedToken(token) nonReentrant {
    // 确保转移金额不为零
    require(amount > 0, "amount must > 0");
    // 获取代币的小数位数
    uint256 tokenDecimals = IERC20(token).decimals();
    // 对转移的代币数量进行精度控制
    uint256 amountWithDecimals = amount.mul(10 ** tokenDecimals);
    // 确保合约余额充足
    require(IERC20(token).balanceOf(address(this)) >= amountWithDecimals, "balance not enough");
    // 转移代币给管理员
    IERC20(token).safeTransfer(msg.sender, amountWithDecimals);
}

// 吊销管理员角色
function revokeAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(ADMIN_ROLE, account);
}

// 授予管理员角色
function grantAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
grantRole(ADMIN_ROLE, account);
}
}

