// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract Helper {

    function _isContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}

contract SimpleSwap is ISimpleSwap, ERC20, Helper{

    address public AToken;
    address public BToken;

    uint256 public reserveAToken;
    uint256 public reserveBToken;


    constructor(address _token0, address _token1) ERC20("SWAP", "LP") {
        require(_token0!=address(0), "zero address not allowed");
        require(_token1!=address(0), "zero address not allowed");
        require(_isContract(_token0), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(_isContract(_token1), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(_token0!=_token1, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        AToken = _token0 < _token1? _token0:_token1;
        BToken = _token0 < _token1? _token1:_token0;
        reserveAToken = 0;
        reserveBToken = 0;
    }


    function swap(address tokenIn, address tokenOut, uint256 amountIn) external override returns (uint256 amountOut) {
        require(tokenIn==AToken || tokenIn==BToken, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut==AToken || tokenOut==BToken, "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenIn!=tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(amountIn!=0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        uint256 reserve0 = reserveAToken;
        uint256 reserve1 = reserveBToken;

        if(tokenIn==AToken) {
            amountOut = (amountIn*reserve1) / (amountIn+reserve0);
            reserveAToken = reserve0 + amountIn;
            reserveBToken = reserve1 - amountOut;
        }
        else {
            amountOut = (amountIn*reserve0) / (amountIn+reserve1);
            reserveAToken = reserve1 + amountIn;
            reserveBToken = reserve0 - amountOut;
        }
        
        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        ERC20(tokenOut).transfer(msg.sender, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }


    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity){
        uint256 _amountA;
        uint256 _amountB;
        uint256 _liquidity;
        (_amountA, _amountB, _liquidity) = _addLiquidity(amountAIn, amountBIn);
        ERC20(AToken).transferFrom(msg.sender, address(this), _amountA);
        ERC20(BToken).transferFrom(msg.sender, address(this), _amountB);
        reserveAToken = ERC20(AToken).balanceOf(address(this));
        reserveBToken = ERC20(BToken).balanceOf(address(this));
        _mint(msg.sender, _liquidity);
        emit AddLiquidity(msg.sender, _amountA, _amountB, _liquidity);
    }

    function _addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountAIn>0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(amountBIn>0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        uint256 reserveA = reserveAToken;
        uint256 reserveB = reserveBToken;
        if(reserveA==0  && reserveB==0){
            (amountA, amountB) = (amountAIn, amountBIn);
        } else {
            uint256 amountBRequired = _quote(amountAIn, reserveA, reserveB);
            uint256 amountARequired = _quote(amountBIn, reserveB, reserveA);
            if(amountBRequired<=amountBIn) {
                (amountA, amountB) = (amountAIn, amountBRequired);
            }
            else{
                (amountA, amountB) = (amountARequired, amountBIn);
            }
        }
        liquidity = Math.sqrt(amountA*amountB);
    }

    function _quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal  returns(uint256 amountB){
        require(amountA>0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveA>0&&reserveB>0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * reserveB / reserveA;
    }

    function removeLiquidity(uint256 liquidity) external override returns (uint256 amountA, uint256 amountB) {
        require(liquidity!=0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        require(allowance(msg.sender, address(this)) >= liquidity, "Insufficient allowance");
        require(liquidity<=balanceOf(msg.sender), "Insufficient Token");
        this.transferFrom(msg.sender, address(this), liquidity);
        (amountA, amountB) = _burnLiquidity(msg.sender);
        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function _burnLiquidity(address to) internal returns(uint256 amountA, uint256 amountB) {
        uint256 reserveA = reserveAToken;
        uint256 reserveB = reserveBToken;
        uint256 liquidity = balanceOf(address(this));
        amountA = liquidity * reserveA / totalSupply();
        amountB = liquidity * reserveB / totalSupply();
        _burn(address(this), liquidity);
        ERC20(AToken).transfer(to, amountA);
        ERC20(BToken).transfer(to, amountB);
    }

    function getReserves() external view override returns (uint256 reserveA, uint256 reserveB) {
        reserveA = reserveAToken;
        reserveB = reserveBToken;
    }

    function getTokenA() external view override returns (address tokenA){
        return AToken;
    }

    function getTokenB() external view override returns (address tokenB){
        return BToken;
    }
}
