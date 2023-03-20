// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MyModifiedSecuredContractWithAdminTransferRecord is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Record {
        uint256 amount;
        address recipient;
        uint256 timestamp;
    }

    mapping(address => mapping(address => Record[])) private _records;
    mapping(address => uint256) private _recordNonces;
    mapping(address => bool) private _whitelistedTokens;

    // 将白名单单独记录为数组
    address[] private _whitelistedTokenList;

    // 增加管理员白名单功能
    function addToWhitelist(address token) external onlyRole(ADMIN_ROLE) {
        _whitelistedTokens[token] = true;
        _whitelistedTokenList.push(token);

        emit AddToWhitelist(token);
    }

    function removeFromWhitelist(address token) external onlyRole(ADMIN_ROLE) {
        _whitelistedTokens[token] = false;

        // 从白名单数组中移除该代币
        for (uint256 i = 0; i < _whitelistedTokenList.length; i++) {
            if (_whitelistedTokenList[i] == token) {
                _whitelistedTokenList[i] = _whitelistedTokenList[_whitelistedTokenList.length - 1];
                _whitelistedTokenList.pop();
                break;
            }
        }

        emit RemoveFromWhitelist(token);
    }

    // 获取管理员设置的白名单列表
    function getWhitelistedTokens() external view returns (address[] memory) {
        return _whitelistedTokenList;
    }

    uint256 private _recordsLimitPerToken = 100;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event AdminTransfer(address indexed from, address indexed to, address indexed token, uint256 amount);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyWhitelistedToken(address token) {
        require(_whitelistedTokens[token], "token not whitelisted");
        _;
    }

    function deposit(address token, uint256 amount) external onlyWhitelistedToken(token) {
        require(amount > 0, "amount must > 0");

        uint256 currentNonce = _recordNonces[msg.sender];
        require(currentNonce < _recordsLimitPerToken, "maximum number of records reached");

        // 获取代币的小数位数
        uint256 tokenDecimals = IERC20(token).decimals();

        // 对转移的代币数量进行精度控制
        uint256 amountWithDecimals = amount.mul(10 ** tokenDecimals);

        // 检查用户是否已经授权代币的转移
        require(IERC20(token).allowance(msg.sender, address(this)) >= amountWithDecimals, "allowance not enough");

        _records[msg.sender][token].push(Record(amount, address(0), block.timestamp)
);
    emit Deposit(msg.sender, token, amount);

    _recordNonces[msg.sender] = currentNonce.add(1);

    // 转移代币
    IERC20(token).safeTransferFrom(msg.sender, address(this), amountWithDecimals);
}

function adminTransfer(address token, address to, uint256 amount) external onlyRole(ADMIN_ROLE) onlyWhitelistedToken(token) nonReentrant {
    require(amount > 0, "amountmust > 0");

    uint256 currentNonce = _recordNonces[msg.sender];
    require(currentNonce < _recordsLimitPerToken, "maximum number of records reached");

    // 获取代币的小数位数
    uint256 tokenDecimals = IERC20(token).decimals();

    // 对转移的代币数量进行精度控制
    uint256 amountWithDecimals = amount.mul(10 ** tokenDecimals);

    // 检查目标地址是否是合约地址
    require(to != address(this), "invalid transfer target");

    // 检查代币余额是否充足
    require(
        IERC20(token).balanceOf(address(this)) >= amountWithDecimals,
        "balance not enough"
    );

    _records[msg.sender][token].push(
        Record(0, to, block.timestamp)
    );

    emit AdminTransfer(msg.sender, to, token, amount);

    _recordNonces[msg.sender] = currentNonce.add(1);

    // 转移代币
    IERC20(token).safeTransfer(to, amountWithDecimals);
}

function getDepositAmount(
    address user,
    address token,
    uint256 nonce
) external view returns (uint256) {
    return _records[user][token][nonce].amount;
}

function getDepositNonce(address user, address token) external view returns (uint256) {
    return _recordNonces[user];
}

function getAdminTransferRecipient(
    address admin,
    address token,
    uint256 nonce
) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
    return _records[admin][token][nonce].recipient;
}

function getAdminTransferNonce(
    address admin,
    address token
) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    return _recordNonces[admin];
}

function getAllowance(address token, address account) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    return IERC20(token).allowance(account, address(this));
}

function withdraw(address token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) onlyWhitelistedToken(token) nonReentrant {
    require(amount > 0, "amount must > 0");

    // 获取代币的小数位数
    uint256 tokenDecimals = IERC20(token).decimals();

    // 对转移的代币数量进行精度控制
    uint256 amountWithDecimals = amount.mul(10 ** tokenDecimals);

    require(IERC20(token).balanceOf(address(this)) >= amountWithDecimals, "balance not enough");

    IERC20(token).safeTransfer(msg.sender, amountWithDecimals);
}

function revokeAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(ADMIN_ROLE, account);
}

function grantAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(ADMIN_ROLE, account);
}

function renounceAdminRole() external {
renounceRole(ADMIN_ROLE, msg.sender);
}

event AddToWhitelist(address token);
event RemoveFromWhitelist(address token);
}

