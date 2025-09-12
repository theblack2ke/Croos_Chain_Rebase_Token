// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    //We need to pass the token address to the constructor
    // Create a deposit function that mints tokens to the user equal to the amount of ETH the user has sent
    // Create a redeem function that burns tokens from the user and sends the user ETH
    // create a way to add rewards to the vault
    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    error Vault__RedeemFailed();

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    /**
     * @notice Allow users to deposit ETH into the vault and mint rebase token in return
     */
    function deposit() external payable {
        // We need to use the amount of ETH the user has sent to mint token to the user
        uint256 interestRate = i_rebaseToken.getInterestRate();
        i_rebaseToken.mint(msg.sender, msg.value, interestRate);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to redeem their rebase tokens for ETH
     * @param _amount The amount of rebase tokens to redeem
     */
    function redeem(uint256 _amount) external {
        // Burn the token from the user
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        i_rebaseToken.burn(msg.sender, _amount);
        // We need to send user ETH
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice get the address of the rebase tokens
     */
    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
