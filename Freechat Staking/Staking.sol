pragma solidity ^0.8.0;

interface Token {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenStaking {
    // 代币合约地址
    address public tokenAddress;
    // 代币总量
    uint public totalTokenAmount;
    // 单个代币的收益
    uint public rewardPerToken;
    // 上次更新时的总奖励金额
    uint public lastTotalRewardAmount;
    // 合约管理员地址
    address public adminAddress;
    // 账户信息
    mapping(address => uint) public balances;
    mapping(address => uint) public lastRewardAmounts;
    mapping(address => uint) public lastUpdateTime;
    mapping(address => bool) public isWhitelisted;
    // 最小质押周期
    uint public minStakeTime;

    constructor(address _tokenAddress, uint _totalTokenAmount, uint _minStakeTime) {
        tokenAddress = _tokenAddress;
        totalTokenAmount = _totalTokenAmount;
        rewardPerToken = 0;
        lastTotalRewardAmount = 0;
        adminAddress = msg.sender;
        minStakeTime = _minStakeTime;
    }

    // 更新单个代币的收益
    function updateRewardPerToken() internal {
        uint currentTotalRewardAmount = address(this).balance;
        if (currentTotalRewardAmount > lastTotalRewardAmount && totalTokenAmount > 0) {
            rewardPerToken += (currentTotalRewardAmount - lastTotalRewardAmount) / totalTokenAmount;
        }
        lastTotalRewardAmount = currentTotalRewardAmount;
    }

    // 质押代币
    function stake(uint amount) external {
        require(amount > 0, "Amount must be greater than zero.");
        require(balances[msg.sender] == 0, "You have already staked tokens.");
        require(isWhitelisted[msg.sender], "You are not allowed to stake tokens.");
        require(minStakeTime == 0 || lastUpdateTime[msg.sender] == 0 || block.timestamp >= lastUpdateTime[msg.sender] + minStakeTime, "You must stake your tokens for at least the minimum stake time.");
        updateRewardPerToken();
        balances[msg.sender] = amount;
        lastRewardAmounts[msg.sender] = amount * rewardPerToken;
        lastUpdateTime[msg.sender] = block.timestamp;
        totalTokenAmount += amount;
        // Transfer tokens to this contract
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
    }

    // 提取质押代币和奖励
    function withdraw() external {
        require(balances[msg.sender] > 0, "You have not staked any tokens.");
        require(minStakeTime == 0 || block.timestamp >= lastUpdateTime[msg.sender] + minStakeTime, "You must stake your tokens for at least the minimum stake time.");
        updateRewardPerToken();
        uint rewardAmount = lastRewardAmounts[msg.sender] + (balances[msg.sender] * (rewardPerToken - lastRewardAmounts[msg.sender] / balances[msg.sender]));
balances[msg.sender] = 0;
lastRewardAmounts[msg.sender] = 0;
lastUpdateTime[msg.sender] = 0;
totalTokenAmount -= rewardAmount;
// Transfer tokens and reward to the user
require(Token(tokenAddress).transfer(msg.sender, balances[msg.sender]), "Token transfer failed.");
require(payable(msg.sender).send(rewardAmount), "Reward transfer failed.");
}

// 添加白名单
function addWhitelist(address account) external {
    require(msg.sender == adminAddress, "Only the admin can add to the whitelist.");
    isWhitelisted[account] = true;
}

// 移除白名单
function removeWhitelist(address account) external {
    require(msg.sender == adminAddress, "Only the admin can remove from the whitelist.");
    isWhitelisted[account] = false;
}

// 设置最小质押周期
function setMinStakeTime(uint time) external {
    require(msg.sender == adminAddress, "Only the admin can set the minimum stake time.");
    minStakeTime = time;
}

// 向合约中添加代币
function depositTokens(uint amount) external {
    require(Token(tokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
    totalTokenAmount += amount;
}

// 从合约中提取代币
function withdrawTokens(uint amount) external {
    require(msg.sender == adminAddress, "Only the admin can withdraw tokens.");
    require(totalTokenAmount >= amount, "Insufficient token balance.");
    require(Token(tokenAddress).transfer(msg.sender, amount), "Token transfer failed.");
    totalTokenAmount -= amount;
}

// 向合约中添加奖励
function depositRewards() external payable {
    require(msg.sender == adminAddress, "Only the admin can deposit rewards.");
}

// 从合约中提取奖励
function withdrawRewards() external {
    require(msg.sender == adminAddress, "Only the admin can withdraw rewards.");
    require(payable(msg.sender).send(address(this).balance), "Reward transfer failed.");
}

//注意，这个合约中使用了一个名为 `Token` 的接口，这个接口代表了一个 ERC-20 标准代币合约，如果你想使用这个合约，你需要在你的代码中导入一个实现了这个接口的代币合约，并把它的地址传递给这个合约的构造函数。另外，这个合约中的 `payable` 关键字用于接收和发送以太币，如果你不需要在这个合约中使用以太币，可以将它们移除。

