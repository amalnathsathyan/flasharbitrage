// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'contracts/IWETH.sol';

contract uniswapSwap {
    address public constant faDAI = 0x3ce6A4a2C2Ad484Cd426011F0883E904910CAEef;
    address public constant faOP = 0x688F927009F8DE48750bC329a998a8a99d0FDe90;
    address public  constant uniRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint24 public constant poolFee = 3000;

    ISwapRouter public immutable swapRouter = ISwapRouter(uniRouter); 

    constructor() {
    }


    function checkAllowance(address _tokenAddress) public view returns(uint256 _tokenAllowance) {
        return IERC20(_tokenAddress).allowance(msg.sender,address(this));
    }
    

    function swapExactInputSingle(uint256 amountIn, address tokenToSell, address tokenToBuy) public returns (uint256 amountOut) {
        
        
        IERC20(tokenToSell).approve(address(swapRouter), amountIn);
        
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenToSell,
                tokenOut: tokenToBuy,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
        return amountOut;  
    }
}