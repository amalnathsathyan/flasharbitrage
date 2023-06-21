// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20WithPermit } from "@aave/core-v3/contracts/interfaces/ERC20WithPermit.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02";

contract FlashloanReceiver is IFlashLoanReceiver {
    address private constant DEX_ADDRESS_1 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant DEX_ADDRESS_2 = 0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30;

    constructor() {}
    
    function dualDexTrade(
        address router1,
        address router2,
        address token1,
        uint256 amount
    ) internal {
        uint256 startBalance = IERC20WithPermit(token1).balanceOf(address(this));
        uint256 token2InitialBalance = IERC20WithPermit(getTokenToBuy(router1)).balanceOf(address(this));
        swap(router1, token1, getTokenToBuy(router1), amount);
        uint256 token2Balance = IERC20WithPermit(getTokenToBuy(router1)).balanceOf(address(this));
        uint256 tradeableAmount = token2Balance - token2InitialBalance;
        swap(router2, getTokenToBuy(router1), token1, tradeableAmount);
        uint256 endBalance = IERC20WithPermit(token1).balanceOf(address(this));
        require(endBalance > startBalance, "Trade Reverted, No Profit Made");
    }
    
    function getTokenToBuy(address router) internal pure returns (address) {
        // Return the address of the token you want to buy on the specified router
        // Replace with your desired token address
        if (router == DEX_ADDRESS_1) {
            return 0xB163A2819aAF8c06aBF46abA4F41D8e7a2ED214f;
        } else if (router == DEX_ADDRESS_2) {
            return 0xB2b7c68F563812d73e9388D89CB92F8cE5Bae6D6;
        }
        revert("Invalid router");
    }
    
    function swap(address router, address tokenIn, address tokenOut, uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        // Approve the tokenIn for spending
        IERC20WithPermit(tokenIn).approve(router, amount);
        
        // Perform the token swap
        IUniswapV2Router02(router).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
    }
}
