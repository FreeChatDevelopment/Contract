pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TokenStaking is Ownable, Pausable {
    using SafeERC20 for IERC20;
    address public tokenAddress = '0x171b1daefac13a0a3524fcb6beddc7b31e58e079';
    uint256 public maxTotalTokenAmount = 1000000 * 10**18; // Maximum staking amount is set to 1,000,000 tokens
    uint256 public totalTokenAmount;
    uint256 public rewardPerToken;
    uint256 public lastTotalRewardAmount;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastRewardAmounts;
    mapping(address => uint256) public depositTimestamps;
    mapping(address => bool) public isBlacklisted;
    uint256 public minStakeTime = 360 days;

    event Staked(address indexed user, uint256 amount);
    event WithdrawnReward(address indexed user, uint256 rewardAmount);
    event WithdrawnPrincipal(address indexed user, uint256 amount);
    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event MaxStakingAmountUpdated(uint256 newMaxStakingAmount);

    constructor() Ownable() Pausable() {}

    function updateRewardPerToken() private {
        uint256 currentTotalRewardAmount = address(this).balance;
        if (
            currentTotalRewardAmount > lastTotalRewardAmount &&
            totalTokenAmount > 0
        ) {
            rewardPerToken =
                rewardPerToken +
                ((currentTotalRewardAmount - lastTotalRewardAmount) *
                    10**IERC20(tokenAddress).decimals()) /
                totalTokenAmount;
        }
        lastTotalRewardAmount = currentTotalRewardAmount;
    }

    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero.");
        require(
            !isBlacklisted[msg.sender],
            "You are not allowed to stake tokens."
        );
        require(
            totalTokenAmount + amount <= maxTotalTokenAmount,
            "Staking amount exceeds maximum limit."
        );
        updateRewardPerToken();
        balances[msg.sender] = balances[msg.sender] + amount;
        lastRewardAmounts[msg.sender] = balances[msg.sender] * rewardPerToken;
        depositTimestamps[msg.sender] = block.timestamp;
        totalTokenAmount = totalTokenAmount + amount;
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        emit Staked(msg.sender, amount);
    }

    function withdrawReward() external whenNotPaused {
        require(balances[msg.sender] > 0, "You have not staked any tokens.");
        require(
            block.timestamp >= depositTimestamps[msg.sender] + minStakeTime,
            "Rewards can only be withdrawn after the 360-day period has expired."
        );
        updateRewardPerToken();
        uint256 rewardAmount = (balances[msg.sender] *
            (rewardPerToken - lastRewardAmounts[msg.sender])) /
            10**IERC20(tokenAddress).decimals();
        lastRewardAmounts[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
        require(success, "Reward transfer failed.");
        emit WithdrawnReward(msg.sender, rewardAmount);
    }

    function withdrawPrincipal(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        require(
            !isBlacklisted[msg.sender],
            "You are not allowed to withdraw tokens."
        );
        updateRewardPerToken();
        balances[msg.sender] -= amount;
        totalTokenAmount -= amount;
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        emit WithdrawnPrincipal(msg.sender, amount);
    }

    function addToBlacklist(address account) external onlyOwner {
        isBlacklisted[account] = true;
        emit BlacklistUpdated(account, true);
    }

    function removeFromBlacklist(address account) external onlyOwner {
        isBlacklisted[account] = false;
        emit BlacklistUpdated(account, false);
    }

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        tokenAddress = newTokenAddress;
    }

    function setMaxStakingAmount(uint256 newMaxStakingAmount)
        external
        onlyOwner
    {
        maxTotalTokenAmount = newMaxStakingAmount;
        emit MaxStakingAmountUpdated(newMaxStakingAmount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function depositRewards() external payable onlyOwner {
        require(msg.sender == owner(), "Only the owner can deposit rewards.");
    }

    function withdrawRewards() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Reward transfer failed.");
    }

    function getTotalStakedTokens() external view returns (uint256) {
        return totalTokenAmount;
    }

    function getStakedTokens(address account) external view returns (uint256) {
        return balances[account];
    }

    function getRewardAmount(address account) external view returns (uint256) {
        if (
            balances[account] == 0 ||
            block.timestamp < depositTimestamps[account] + minStakeTime
        ) {
            return 0;
        }
        uint256 currentRewardPerToken = rewardPerToken;
        uint256 currentTotalRewardAmount = address(this).balance;
        if (
            currentTotalRewardAmount > lastTotalRewardAmount &&
            totalTokenAmount > 0
        ) {
            currentRewardPerToken =
                currentRewardPerToken +
                ((currentTotalRewardAmount - lastTotalRewardAmount) *
                    10**IERC20(tokenAddress).decimals()) /
                totalTokenAmount;
        }
        return
            (balances[account] *
                (currentRewardPerToken - lastRewardAmounts[account])) /
            10**IERC20(tokenAddress).decimals();
    }
}
