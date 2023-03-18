// Solidity编译版本
pragma solidity ^0.8.0;

// FreechatCoin代币的ERC20合约接口
interface FreechatCoin {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// MyContract合约
contract MyContract {
    // 声明FreechatCoin代币合约实例和管理员地址
    FreechatCoin public freechatCoin;
    address public admin;

    // 存放用户存款记录的结构体
    struct Record {
        uint256 depositAmount;
        uint256 depositNonce;
        uint256 transferNonce;
    }

    // 存放用户存款记录的映射
    mapping(address => Record) public records;

    // 构造函数，初始化合约时传入FreechatCoin代币合约地址
    constructor(address freechatCoinAddress) {
        freechatCoin = FreechatCoin(freechatCoinAddress);
        admin = 0x403dD792F7d10e6Ffb7339F383a3Bf862c84c80f; // 设置管理员地址
    }

    // 存款函数，用户通过此函数向合约地址存入代币
    function deposit(uint256 amount, uint256 nonce) public {
        require(amount > 0, "Deposit amount must be greater than 0"); // 检查存款数量是否大于0
        require(nonce == records[msg.sender].depositNonce + 1, "Invalid nonce"); // 检查nonce是否连续

        // 将用户的代币转入合约地址
        require(freechatCoin.transferFrom(msg.sender, address(this), amount), "Failed to transfer Freechat Coins");

        // 更新用户存款记录
        Record storage record = records[msg.sender];
        record.depositAmount += amount;
        record.depositNonce = nonce;
    }

    // 转账函数，仅限管理员调用，用于从合约地址向其他地址转账代币
    function transfer(address to, uint256 amount, uint256 nonce) public {
        require(msg.sender == admin, "Only admin can call this function"); // 仅限管理员调用
        require(amount > 0, "Transfer amount must be greater than 0"); // 检查转账数量是否大于0
        require(nonce == records[address(this)].transferNonce + 1, "Invalid nonce"); // 检查nonce是否连续
        require(freechatCoin.allowance(address(this), admin) >= amount, "Contract does not have sufficient allowance"); // 检查合约是否有足够的授权
        require(to != address(0), "Invalid recipient address"); // 检查收款地址是否合法

        // 执行代币转账
        require(freechatCoin.transfer(to, amount), "Failed to transfer Freechat Coins");

        // 更新转账记录
        Record storage record = records[address(this)];
        record.transferNonce = nonce;
    }
}
