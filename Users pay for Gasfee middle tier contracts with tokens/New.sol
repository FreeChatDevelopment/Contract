// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenGasFeeProxy {
    using SafeMath for uint256;

    // 定义白名单映射
    mapping(address => bool) public whitelist;

    // 定义合约拥有者
    address public owner;

    // ERC20 代币合约地址
    address private _tokenAddress;

    // 代币价格预言机合约地址
    address private _priceFeedAddress;

    // LINK 价格预言机合约地址
    address private _linkPriceFeedAddress;

    // Gas 价格预言机合约地址
    address private _gasPriceFeedAddress;

    // 修改构造函数以接收 LINK 价格预言机地址和 Gas 价格预言机地址
    constructor(address tokenAddress, address priceFeedAddress, address linkPriceFeedAddress, address gasPriceFeedAddress) {
        _tokenAddress = tokenAddress;
        _priceFeedAddress = priceFeedAddress;
        _linkPriceFeedAddress = linkPriceFeedAddress;
        _gasPriceFeedAddress = gasPriceFeedAddress;
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
    
        // 获取代币价格
    function getTokenPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid token price");
        return uint256(price);
    }

    // 获取 LINK 价格
    function getLinkPrice() public view returns (uint256) {
        AggregatorV3Interface linkPriceFeed = AggregatorV3Interface(_linkPriceFeedAddress);
        (, int256 linkPrice, , , ) = linkPriceFeed.latestRoundData();
        require(linkPrice > 0, "Invalid LINK price");
        return uint256(linkPrice);
    }

    // 获取 Gas 价格
    function getGasPrice() public view returns (uint256) {
        AggregatorV3Interface gasPriceFeed = AggregatorV3Interface(_gasPriceFeedAddress);
        (, int256 gasPrice, , , ) = gasPriceFeed.latestRoundData();
        require(gasPrice > 0, "Invalid gas price");
        return uint256(gasPrice);
    }
    
        // 获取精准的 gas fee，包括 LINK 代币价值
    function getAccurateGasFee() public view returns (uint256) {
        uint256 gas = gasleft();
        uint256 gasPrice = getGasPrice();
        uint256 gasFeeInGwei = gas * gasPrice;

        // 获取代币价格
        uint256 tokenPrice = getTokenPrice();

        // 获取 LINK 价格
        uint256 linkPrice = getLinkPrice();

        // 计算 LINK 代币价值
        uint256 linkTokenValue = linkPrice.mul(1e18).div(tokenPrice);

        // 根据实际的 gas limit 和代币价格计算 gas 费用
        uint256 gasFeeInTokens = gasFeeInGwei.mul(tokenPrice).add(linkTokenValue);
        return gasFeeInTokens;
    }

    // 转账函数，帮助用户支付 gas fee
    function transferTokensAndPayGas(
        address to,
        uint256 amount
    ) public {
        require(amount > 0, "Amount must be greater than 0");
        require(whitelist[_tokenAddress], "Token not in whitelist");
        require(to != address(0), "Invalid recipient address");

        // 转账代币到合约地址
        transferTokens(amount);

        // 获取当前 gas 费用，包括 LINK 代币价值
        uint256 gasCost = getAccurateGasFee();

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

    function withdrawAll() public onlyOwner {
        // 提取代币
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        if (tokenBalance > 0) {
            token.transfer(owner, tokenBalance);
        }

        // 提取 ETH
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool success, ) = msg.sender.call{value: ethBalance}("");
            require(success, "ETH withdraw failed");
        }
    }
}
