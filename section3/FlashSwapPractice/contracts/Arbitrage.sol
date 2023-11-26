// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";

// This is a practice contract for flash swap arbitrage
contract Arbitrage is IUniswapV2Callee, Ownable {

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Withdraw failed");
    }

    //
    // EXTERNAL NON-VIEW
    //
    
    event TEST(uint256 indexed balance);
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        (address priceHigherPool, address priceLowerPool, uint256 borrowETH, uint256 getUSDCAmountIn) = abi.decode(data, (address, address, uint256, uint256));
        require(sender==address(this), "sender error");
        require(msg.sender==priceLowerPool, "msg.sender error");
        
        (uint256 priceHigherReserve0, uint256 priceHigherReserve1, uint32 time) = IUniswapV2Pair(priceHigherPool).getReserves(); // token0 = WETH, token1 = USDC
        uint256 getUSDCAmountOut = _getAmountOut(borrowETH, priceHigherReserve0, priceHigherReserve1);
        
        address token0 = IUniswapV2Pair(priceHigherPool).token0();
        IERC20(token0).transfer(priceHigherPool, borrowETH);
        IUniswapV2Pair(priceHigherPool).swap(0, getUSDCAmountOut, address(this), bytes(""));
        address token1 = IUniswapV2Pair(priceLowerPool).token1();
        IERC20(token1).transfer(priceLowerPool, getUSDCAmountIn);
    }

    // Method 1 is
    //  - borrow WETH from lower price pool
    //  - swap WETH for USDC in higher price pool
    //  - repay USDC to lower pool
    // Method 2 is
    //  - borrow USDC from higher price pool
    //  - swap USDC for WETH in lower pool
    //  - repay WETH to higher pool
    // for testing convenient, we implement the method 1 here
    function arbitrage(address priceLowerPool, address priceHigherPool, uint256 borrowETH) external {
        (uint256 priceLowerReserve0, uint256 priceLowerReserve1, uint32 time) = IUniswapV2Pair(priceLowerPool).getReserves(); // token0 = WETH, token1 = USDC
        uint256 getUSDCAmountIn = _getAmountIn(borrowETH, priceLowerReserve1, priceLowerReserve0);
        emit TEST(getUSDCAmountIn);
        bytes memory data = abi.encode(priceHigherPool, priceLowerPool, borrowETH, getUSDCAmountIn);
        IUniswapV2Pair(priceLowerPool).swap(borrowETH, 0, address(this), data);
    }

    //
    // INTERNAL PURE
    //

    // copy from UniswapV2Library
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
