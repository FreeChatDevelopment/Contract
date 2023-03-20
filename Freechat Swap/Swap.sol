// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.0;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

// 交换示例合约
contract SwapExamples {
    ISwapRouter public immutable swapRouter; // 交换路由器
    IUniswapV3Factory public immutable uniswapFactory; // Uniswap V3工厂合约

    uint24 public constant poolFee = 3000; // 池子手续费

    address public owner; // 合约拥有者

    mapping(address => uint256) public feesBalance; // 费用余额映射

    // 构造函数，传入交换路由器和Uniswap V3工厂合约
    constructor(ISwapRouter _swapRouter, IUniswapV3Factory _uniswapFactory) {
        swapRouter = _swapRouter;
        uniswapFactory = _uniswapFactory;
        owner = msg.sender;
    }

    // 仅限合约拥有者修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // 转移合约拥有权
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // 获取tokenIn到tokenOut的WETH价格
    function _getPriceInWETH(address tokenIn, address tokenOut) internal view returns (uint256) {
        address poolAddress = uniswapFactory.getPool(tokenIn, tokenOut, poolFee);
        require(poolAddress != address(0), "Pool not found");

        IUniswapV3Pool tokenPool = IUniswapV3Pool(poolAddress);

        (uint160 sqrtPriceX96,,,,,) = tokenPool.slot0();
        uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);

        return priceX96;
    }

    // 估算Gas费用（以token计价）
    function estimateGasFeeInToken(address tokenIn, address tokenOut, uint256 gasAmount) public view returns (uint256) {
        uint256 gasPrice = tx.gasprice;
        uint256 ethAmount = gasPrice * gasAmount;
        uint256 priceInWETH = _getPriceInWETH(tokenIn, tokenOut);
        return (ethAmount * 1 ether) / priceInWETH;
    }

    // 估算合约手续费（以token计价）
    function estimateContractFeeInToken(address tokenIn, address tokenOut, uint256 contractFee) public view returns (uint256) {
        uint256 priceInWETH = _getPriceInWETH(tokenIn, tokenOut);
        return (contractFee * 1 ether) / priceInWETH;
    }

     // 计算Token手续费
    function _calculateTokenFee(address tokenIn, address tokenOut, uint256 amountIn, uint256 gasFee, uint256 contractFee) internal view returns (uint256) {
        uint256 tokenValue = estimateGasFeeInToken(tokenIn, tokenOut, gasFee) + estimateContractFeeInToken(tokenIn, tokenOut, contractFee);
        return (amountIn * tokenValue) / 10000;
    }

    // 带Token手续费的兑换
    function swapWithTokenFee(address tokenIn, address tokenOut, uint256 amountIn, uint256 gasFee, uint256 contractFee) external returns (uint256 amountOut) {
        // 计算Token手续费
        uint256 tokenFee = _calculateTokenFee(tokenIn, tokenOut, amountIn, gasFee, contractFee);
        uint256 amountInWithFee = amountIn + tokenFee;

        // 将Token转移到合约地址
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInWithFee);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountInWithFee);

        // 兑换以支付手续费
        ISwapRouter.ExactInputSingleParams memory feeParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp + 180,
            amountIn: tokenFee,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        swapRouter.exactInputSingle(feeParams);

        // 用剩余的代币进行兑换
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp + 180,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        amountOut = swapRouter.exactInputSingle(params);

        // 累积合约手续费到费用余额
        feesBalance[tokenIn] += estimateContractFeeInToken(tokenIn, tokenOut, contractFee);
    }

    // 提现手续费
    function withdrawFees(address token) external onlyOwner {
        uint256 amount = feesBalance[token];
        require(amount > 0, "No fees to withdraw");

        feesBalance[token] = 0;
        TransferHelper.safeTransfer(token, owner, amount);
    }
}
