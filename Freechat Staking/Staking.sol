// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TokenStaking is Ownable, Pausable {
    using SafeERC20 for IERC20;
    //ERC20token地址
    address public tokenAddress;
    //ERC20token精度
    uint8 private decimals = 18;
    //Token的最大总发行量
    uint public maxTotalTokenAmount = 1000000 * 10**decimals; // Maximum staking amount is set to 1,000,000 tokens
    //Token当前总量
    uint public totalTokenAmount;
    //用户token余额列表
    mapping(address => uint) public balances;
    //黑名单列表
    mapping(address => bool) public isBlacklisted;

    event Staked(address indexed user, uint amount);
    event WithdrawnPrincipal(address indexed user, uint amount);
    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event MaxStakingAmountUpdated(uint newMaxStakingAmount);

    constructor(address token) Ownable() Pausable() {
        tokenAddress = token;
    }
   
    //用户存款
    function stake(uint amount) external whenNotPaused {
        //判断存储数额是否大于0
        require(amount > 0, "Amount must be greater than zero.");
        //判断用户是否在黑名单中
        require(!isBlacklisted[msg.sender], "You are not allowed to stake tokens.");
        //判断合约存款总额是否超过最大额度
        require(totalTokenAmount + amount <= maxTotalTokenAmount, "Staking amount exceeds maximum limit.");
        //为用户存入token
        balances[msg.sender] = balances[msg.sender] + amount;
        //token总存储数额增加
        totalTokenAmount = totalTokenAmount + amount;
        //用户将token转给合约
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }
        //余额提现，用户地址调用此方法可以提现amount数额的token
    function withdraw(uint amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        require(!isBlacklisted[msg.sender], "You are not allowed to withdraw tokens.");
        balances[msg.sender] -= amount;
        totalTokenAmount -= amount;
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        emit WithdrawnPrincipal(msg.sender, amount);
    }
    //将此地址用户添加到黑名单列表中
    function addToBlacklist(address account) external onlyOwner {
        isBlacklisted[account] = true;
        emit BlacklistUpdated(account, true);
    }
    //将此地址用户从黑名单列表中移除
    function removeFromBlacklist(address account) external onlyOwner {
        isBlacklisted[account] = false;
        emit BlacklistUpdated(account, false);
    }
    //设置token地址
    function setTokenAddress(address newTokenAddress) external onlyOwner {
        tokenAddress = newTokenAddress;
    }
    //设置最大存入token数量
    function setMaxStakingAmount(uint newMaxStakingAmount) external onlyOwner {
        maxTotalTokenAmount = newMaxStakingAmount;
        emit MaxStakingAmountUpdated(newMaxStakingAmount);
    }
    //合约暂停函数，用来发现bug或遭受攻击时暂停合约运行
    function pause() external onlyOwner {
        _pause();
    }
    //恢复合约运行函数，用来恢复被暂停的合约
    function unpause() external onlyOwner {
        _unpause();
    }
    function getTotalStakedTokens() external view returns (uint) {
        //获取当前Token总额
        return totalTokenAmount;
    }

    function getStakedTokens(address account) external view returns (uint) {
        //获取该地址当前staking余额
        return balances[account];
    }


}

