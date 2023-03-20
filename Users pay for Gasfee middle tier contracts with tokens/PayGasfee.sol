// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 引入 SafeMath 和 IERC20 库
import "./SafeMath.sol";
import "./IERC20.sol";

// 中间层合约
contract TokenGasFeeProxy {
    using SafeMath for uint256;

    // 定义白名单映射
    mapping(address => bool) public whitelist;

    // 定义合约拥有者
    address public owner;

    // 定义 gas fee 映射
    mapping(address => uint256) public gasFees;

    // ERC20 代币合约地址
    address private _tokenAddress;

    // 初始化函数
    constructor(address tokenAddress) {
        _tokenAddress = tokenAddress;
        owner = msg.sender;
    }

    // 添加到白名单
    function addToWhitelist(address tokenAddress) public onlyOwner {
        whitelist[tokenAddress] = true;
    }

    // 从白名单移除
    function removeFromWhitelist(address tokenAddress) public onlyOwner {
        whitelist[tokenAddress] = false;
    }

    // 转账函数，转账代币到合约地址
    function transferTokens(uint256 amount) internal {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
    }

    // 转账代币给接收地址
    function transferTokensTo(
        address to,
        uint256 amount
    ) internal {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(to, amount), "Transfer failed");
    }

    // 设定 gas fee
    function setGasFee(uint256 gasFee) public onlyOwner {
        gasFees[msg.sender] = gasFee;
    }

    // 获取 gas fee
    function getGasFee(address sender) public view returns (uint256) {
        return gasFees[sender];
    }

    // 转账函数，帮助用户支付 gas fee
    function transferTokensAndPayGas(
        address to,
        uint256 amount,
        uint256 gasLimit
    ) public {
        // 检查转账金额是否大于0
        require(amount > 0, "Amount must be greater than 0");

        // 检查代币是否在白名单中
        require(whitelist[_tokenAddress], "Token not in whitelist");

        // 检查接收地址是否有效
        require(to != address(0), "Invalid recipient address");

        // 转账代币到合约地址
        transferTokens(amount);

        // 获取当前 gas 费用
        uint256 gasPrice = tx.gasprice;
        uint256 gasCost = gasPrice * gasLimit;

        // 检查合约余额是否足够支付 gas 费用和转账金额
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= gasCost.add(amount),
            "Insufficient balance"
        );

        // 转账代币到接收地址
        transferTokensTo(to, amount);

        // 转账 gas 费用到矿工地址
        address payable miner = payable(msg.sender);
        miner.transfer(gasCost);
    }

     // 仅限合约拥有者调用的修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // 获取 ETH 的 gas 费用
    function getGasFee() public view returns (uint256) {
        uint256 gas = gasleft(); // 获取当前交易还剩余的 gas limit
        uint256 gasPrice = tx.gasprice; // 获取当前 gas 价格
        uint256 gasFee = gas * gasPrice; // 根据实际的 gas limit 计算 gas 费用
        return gasFee;
    }

    // 转账 ETH 函数，帮助用户支付 gas fee
    function transferETHAndPayGas(address payable to) public payable {
        // 检查接收地址是否有效
        require(to != address(0), "Invalid recipient address");

        // 获取 gas 费用
        uint256 gasFee = getGasFee();

        // 检查合约余额是否足够支付 gas 费用和转账金额
        require(
            address(this).balance >= msg.value.add(gasFee),
            "Insufficient balance"
        );

        // 转账 ETH 到接收地址
        to.transfer(msg.value);

        // 转账 gas 费用到矿工地址
        address payable miner = payable(msg.sender);
        miner.transfer(gasFee);
    }

    // 提取合约余额中的代币，仅限合约拥有者调用
    function withdrawTokens(uint256 amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        token.transfer(owner, amount);
    }

    //提取ETH余额
    function withdrawETH() public onlyOwner {
        require(address(this).balance > 0, "Contract balance is 0");

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}
