// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IBank.sol";
import "../helpers/IERC20.sol";
import "./Roles.sol";

abstract contract Bank is IBank, Roles {

    modifier availableBalance(address tokenAddress, uint256 amount) {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) - _blockedAmountForToken(tokenAddress) >= amount,
            Errors.BALANCE_NOT_AVAILABLE
        );
        _;
    }

    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    )
        external
        override
        contractOwner(msg.sender)
        availableBalance(tokenAddress, amount)
    {
        IERC20(tokenAddress).transfer(recipient, amount);
        emit Withdrawal(tokenAddress, recipient, amount);
    }


    function _blockedAmountForToken(
        address token
    )
        internal
        virtual
        returns(uint256);
}
