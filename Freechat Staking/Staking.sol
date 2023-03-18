pragma solidity ^0.8.0;

interface Token {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenStaking {
    address public tokenAddress = 0x171b1daefac13a0a3524fcb6beddc7b31e58e079;
    uint public totalTokenAmount;
    uint public rewardPerToken;
    uint public lastTotalRewardAmount;
    address public adminAddress;
    mapping(address => uint) public balances;
    mapping(address => uint) public lastRewardAmounts;
    mapping(address => uint) public depositTimestamps;
    mapping(address => bool) public isWhitelisted;
    uint public minStakeTime = 360 days;

    constructor() {
        adminAddress = msg.sender;
    }

    function updateRewardPerToken() internal {
        uint currentTotalRewardAmount = address(this).balance;
        if (currentTotalRewardAmount > lastTotalRewardAmount && totalTokenAmount > 0) {
            rewardPerToken += (currentTotalRewardAmount - lastTotalRewardAmount) / totalTokenAmount;
        }
        lastTotalRewardAmount = currentTotalRewardAmount;
    }

    function stake(uint amount) external {
        require(amount > 0, "Amount must be greater than zero.");
        require(isWhitelisted[msg.sender], "You are not allowed to stake tokens.");
        updateRewardPerToken();
        balances[msg.sender] += amount;
        lastRewardAmounts[msg.sender] = balances[msg.sender] * rewardPerToken;
        depositTimestamps[msg.sender] = block.timestamp;
        totalTokenAmount += amount;
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
    }

    function withdrawReward() external {
        require(balances[msg.sender] > 0, "You have not staked any tokens.");
        require(block.timestamp >= depositTimestamps[msg.sender] + minStakeTime, "Rewards can only be withdrawn after the 360-day period has expired.");
        updateRewardPerToken();
        uint rewardAmount = balances[msg.sender] * (rewardPerToken - lastRewardAmounts[msg.sender] / balances[msg.sender]);
        lastRewardAmounts[msg.sender] = 0;
        require(payable(msg.sender).send(rewardAmount), "Reward transfer failed.");
    }

    function withdrawPrincipal(uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        require(isWhitelisted[msg.sender], "You are not allowed to withdraw tokens.");
        updateRewardPerToken();
        balances[msg.sender] -= amount;
        totalTokenAmount -= amount;
        require(Token(tokenAddress).transfer(msg.sender, amount), "Token transfer failed.");
    }

    function addWhitelist(address account) external {
        require(msg.sender == adminAddress, "Only the admin can add to the whitelist.");
        isWhitelisted[account] = true;
    }

    function removeWhitelist(address account) external {
        require(msg.sender == adminAddress, "Only the admin can remove from the whitelist.");
        isWhitelisted[account] = false;
}

function setAdminAddress(address newAdminAddress) external {
    require(msg.sender == adminAddress, "Only the admin can change the admin address.");
    adminAddress = newAdminAddress;
}

function depositRewards() external payable {
    require(msg.sender == adminAddress, "Only the admin can deposit rewards.");
}

function withdrawRewards() external {
    require(msg.sender == adminAddress, "Only the admin can withdraw rewards.");
    require(payable(msg.sender).send(address(this).balance), "Reward transfer failed.");
}

function getTotalStakedTokens() external view returns (uint) {
    return totalTokenAmount;
}

function getStakedTokens(address account) external view returns (uint) {
    return balances[account];
}

function getRewardAmount(address account) external view returns (uint) {
    if (balances[account] == 0 || block.timestamp < depositTimestamps[account] + minStakeTime) {
        return 0;
    }
    uint currentRewardPerToken = rewardPerToken;
    uint currentTotalRewardAmount = address(this).balance;
    if (currentTotalRewardAmount > lastTotalRewardAmount && totalTokenAmount > 0) {
        currentRewardPerToken += (currentTotalRewardAmount - lastTotalRewardAmount) / totalTokenAmount;
    }
    return balances[account] * (currentRewardPerToken - lastRewardAmounts[account] / balances[account]);
}


