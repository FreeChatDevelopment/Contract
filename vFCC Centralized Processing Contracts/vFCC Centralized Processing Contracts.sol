// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MySecuredContractWithAdminTransferRecord is AccessControl, ReentrancyGuard {
using SafeMath for uint256;
IERC20 private _freechatCoin;
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
struct Record {
    uint256 depositAmount;
    uint256 depositNonce;
    uint256 adminTransferAmount;
    uint256 adminTransferNonce;
    address recipient;
    uint256 timestamp;
}

mapping(address => Record[]) private _records;

uint256 private constant RECORDS_LIMIT = 100;

event Deposit(address indexed user, uint256 amount, uint256 nonce);
event AdminTransfer(address indexed from, address indexed to, uint256 amount, uint256 nonce);

constructor(IERC20 freechatCoin) {
    _freechatCoin = freechatCoin;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
}

function deposit(uint256 amount) external {
    require(amount > 0, "Deposit amount must be greater than 0");
    uint256 currentNonce = _records[msg.sender].length.add(1);
    _records[msg.sender].push(Record(amount, currentNonce, 0, 0, address(0), block.timestamp));
    emit Deposit(msg.sender, amount, currentNonce);
    require(_freechatCoin.transferFrom(msg.sender, address(this), amount), "Deposit failed");
}

function adminTransfer(address to, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant {
    require(amount > 0, "Transfer amount must be greater than 0");
    require(to != address(0), "Invalid recipient address");
    require(_records[msg.sender].length < RECORDS_LIMIT, "Too many records");
    uint256 currentNonce = _records[msg.sender].length.add(1);
    _records[msg.sender].push(Record(0, 0, amount, currentNonce, to, block.timestamp));
    require(_freechatCoin.balanceOf(address(this)) >= amount, "Insufficient balance in contract");
    require(_freechatCoin.allowance(owner(), address(this)) >= amount, "Contract is not authorized to transfer enough tokens");
    require(_freechatCoin.transfer(to, amount), "Transfer failed");
    emit AdminTransfer(msg.sender, to, amount, currentNonce);
}

function getDepositAmount(address user, uint256 nonce) public view returns (uint256) {
    for (uint256 i = 0; i < _records[user].length; i++) {
        if (_records[user][i].depositNonce == nonce) {
            return _records[user][i].depositAmount;
        }
    }
    revert("Record not found");
}

function getDepositNonce(address user) public view returns (uint256) {
    return _records[user].length;
}

function getAdminTransferAmount(address admin, uint256 nonce) public view onlyRole(ADMIN_ROLE) returns (uint256) {
    for (uint256 i = 0; i < _records[admin].length; i++) {
        if (_records[admin][i].adminTransferNonce == nonce) {
            return _records[admin][i].adminTransferAmount;
        }
    }
    revert("Record not found");
}

function getAdminTransferNonce(address admin) public view onlyRole(ADMIN_ROLE) returns (uint256) {
return _records[admin].length;
}
function getRecipient(address admin, uint256 nonce) public view onlyRole(ADMIN_ROLE) returns (address) {
    for (uint256 i = 0; i < _records[admin].length; i++) {
        if (_records[admin][i].adminTransferNonce == nonce) {
            return _records[admin][i].recipient;
        }
    }
    revert("Record not found");
}

function getBalance() external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    return _freechatCoin.balanceOf(address(this));
}

function getAllowance() external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    return _freechatCoin.allowance(owner(), address(this));
}

function withdraw(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(amount <= _freechatCoin.balanceOf(address(this)), "Insufficient balance in contract");
    require(_freechatCoin.transfer(owner(), amount), "Withdrawal failed");
}

function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    uint256 amount = _freechatCoin.balanceOf(address(this));
    require(_freechatCoin.transfer(owner(), amount), "Emergency withdrawal failed");
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