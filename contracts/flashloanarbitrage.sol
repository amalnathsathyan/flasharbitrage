// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFlashLoanReceiver } from "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanReceiver.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressProvider.sol"
import { IERC20WithPermit } from "@aave/core-v3/contracts/interfaces/ERC20WithPermit.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02";

contract FlashloanReceiver is IFlashLoanReceiver {
    ILendingPoolAddressesProvider private constant PROVIDER_ADDRESS = ILendingPoolAddressesProvider(0x0496275d34753A48320CA58103d5220d394FF77F);
    address private constant DEX_ADDRESS_1 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant DEX_ADDRESS_2 = 0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30;

    constructor() {}

    function executeOperation(
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory premiums,
        address initiator,
        bytes memory params
    ) external override returns(bool) {
        // Handle flashloan logic here
        
        // Check if the caller is the Aave lending pool
        require(msg.sender == getLendingPool(), "Invalid caller");

        // Access the borrowed asset
        address borrowedAsset = assets[0];

        // Calculate the amount to borrow and repay
        uint256 borrowedAmount = amounts[0];
        uint256 totalRepayAmount = borrowedAmount + premiums[0];

        // Ensure the contract has sufficient funds to repay the loan
        require(
            IERC20WithPermit(borrowedAsset).balanceOf(address(this)) >= totalRepayAmount,
            "Insufficient funds to repay the loan"
        );

        // Perform flashloan logic
        
        // Swap the borrowed asset on DEX1 and DEX2
        dualDexTrade(DEX_ADDRESS_1, DEX_ADDRESS_2, borrowedAsset, totalRepayAmount);

        // Repay the flashloan
        IERC20WithPermit(borrowedAsset).transfer(msg.sender, totalRepayAmount);

        // Do any other desired operations
        // ...
    }

    function getLendingPool() internal view returns (address) {
        return PROVIDER_ADDRESS.getLendingPool();
    }
    
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
            return ;
        } else if (router == DEX_ADDRESS_2) {
            return 0xYourTokenAddress2;
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
