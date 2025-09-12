// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Rebase Token
 * @author 2ke
 * @notice This is a cross chain rebase token that incentivises users to deposit into a vault and gain interest in reward
 * @notice  The interest rate in this smart contract can only decrease
 * @notice Each user will have their own interest rate that is the global interest rate at the time of deposit
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    // ERRORS
    error RebaseToken__InterestRateDecreased(uint256 interestRates, uint256 newIntersteRate);

    // State variable
    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_ANS_BURN_ROLE");
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRated(uint256 newIntersteRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /**
     * @notice Set the interest rate in the contract
     * @param _newIntersteRate the new interest rate to set
     * @dev the interest rate Can only decrease
     */
    function setInterestRate(uint256 _newIntersteRate) external onlyOwner {
        if (_newIntersteRate >= s_interestRate) {
            revert RebaseToken__InterestRateDecreased(s_interestRate, _newIntersteRate);
        }
        s_interestRate = _newIntersteRate;
        emit InterestRated(_newIntersteRate);
    }

    /**
     * @notice Get the principal balance of a user, This is the number of tokens that have currently been minted to the user (NO INTEREST RATE)
     * @param _user The user principal balance address
     * @return The principal balance of the user
     */
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Mint the user token when they deposit into the vault
     */
    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    /**
     *  @notice Burn the user tokens when they withdraw from the vault
     * @param _from The user to burn the tokens from
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    function balanceOf(address _user) public view override returns (uint256) {
        // get the user principal balance (that has been already minted)
        //multiply the principal balance by the InterestRate that has accumulates in the time since it was last updated
        return (super.balanceOf(_user) * _calculateUserAccumulateInterestSinceLastUpdate(_user)) / PRECISION_FACTOR;
    } // PRINCIPALBALANCE + INTERESTRATE

    /**
     * @notice Transfer tokens from one user to another
     * @param _recipient The user to transfer the tokens to
     * @param _amount The amount of tokens to transfer
     * @return True if the transfer was successful
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            // If the recipient doesn't has an active balance we set his interest Rate to the msg.sender's one
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Transfer tokens from onr useer to another
     * @param _sender  The user to transfer the tokens from
     * @param _recipient The user to transfer the tokens to
     * @param _amount The amount of token to transfer
     * @return True if the transfer was successful
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            // If the recipient doesn't has an active balance we set his interest Rate to the msg.sender's one
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    function _calculateUserAccumulateInterestSinceLastUpdate(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);

        return linearInterest;
    }

    /**
     * @notice  Mint the accrued interest to the user since the time they interacted with the protocol (e.g burn, mint, transfer )
     * @param _user to mint the accrued interest to
     */
    function _mintAccruedInterest(address _user) internal {
        // Find the current balance of rebase tokens that have been minted to the user. --> Actual balance
        uint256 previousPrincipalBalance = super.balanceOf(_user);
        // Calculate their current balance including any interest --> balanceOf
        uint256 currentBalance = balanceOf(_user);
        // calculate the number of tokens that need to be minted to the user  -->  number of token that should be minted
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;
        //set the users last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        // call _mint to mint the token to the user
        _mint(_user, balanceIncrease);
    }

    /**
     * @notice Get the interest rate that id currently set for the contract. Any future depositors will receive this interest rate
     * @return The interestrate for the contract
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice Get the interest Rate for the _user
     * @param _user The user to get the interest Rate for
     */
    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
