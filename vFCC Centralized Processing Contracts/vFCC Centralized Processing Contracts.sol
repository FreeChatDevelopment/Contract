根据这份合约，写一个GO语言的交互代码。
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入OpenZeppelin库的IERC20和Ownable接口
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// MySecuredContractWithAdminTransferRecord合约，继承自Ownable
contract MySecuredContractWithAdminTransferRecord is Ownable {
    // 声明_freechatCoin为IERC20接口类型，存储FreechatCoin代币合约的实例
    IERC20 private _freechatCoin;

    // 存放用户存款记录和管理员转账记录的结构体
    struct Record {
        uint256 depositAmount; // 用户存款数量
        uint256 depositNonce; // 用户存款操作计数器
        uint256 adminTransferAmount; // 管理员转账数量
        uint256 adminTransferNonce; // 管理员转账操作计数器
    }

    // 存放用户存款记录和管理员转账记录的映射，键为地址，值为Record结构体实例
    mapping(address => Record) private _records;

    // 事件：用户存款
    event Deposit(address indexed user, uint256 amount, uint256 nonce);
    // 事件：管理员转账
    event AdminTransfer(address indexed from, address indexed to, uint256 amount, uint256 nonce);

    // 构造函数，初始化合约时传入FreechatCoin代币合约实例
    constructor(IERC20 freechatCoin) {
        _freechatCoin = freechatCoin;
    }

    // 存款函数，用户通过此函数向合约地址存入代币
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0"); // 检查存款数量是否大于0

        uint256 currentNonce = _records[msg.sender].depositNonce + 1; // 计算当前nonce值

        // 更新用户存款记录
        _records[msg.sender].depositAmount += amount;
        _records[msg.sender].depositNonce = currentNonce;

        // 将用户的代币转入合约地址
        _freechatCoin.transferFrom(msg.sender, address(this), amount);

        // 触发存款事件
        emit Deposit(msg.sender, amount, currentNonce);
    }

    // 管理员转账函数，仅限管理员调用，用于从合约地址向其他地址转账代币
    function adminTransfer(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Transfer amount must be greater than 0"); // 检查转账数量是否大于0
        require(to != address(0), "Invalid recipient address"); // 检查收款地址是否合法

        uint256 currentNonce = _records[msg.sender].adminTransferNonce + 1; // 计算当前nonce值

        // 更新管理员转账记录
        _records[msg.sender].adminTransferAmount += amount;
        _records[msg.sender].adminTransferNonce = currentNonce;

        // 执行代币转账
        _freechatCoin.transferFrom(msg.sender, to, amount);

        // 触发管理员转账事件
        emit AdminTransfer(msg.sender, to, amount, currentNonce);
    }
  
// 获取用户的存款金额
function getDepositAmount(address user) external view returns (uint256) {
return _records[user].depositAmount;
}

// 获取用户的存款操作次数
function getDepositNonce(address user) external view returns (uint256) {
    return _records[user].depositNonce;
}

// 获取管理员的转账金额
function getAdminTransferAmount(address admin) external view returns (uint256) {
    return _records[admin].adminTransferAmount;
}

// 获取管理员的转账操作次数
function getAdminTransferNonce(address admin) external view returns (uint256) {
    return _records[admin].adminTransferNonce;
}
