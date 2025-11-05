// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {Pool} from "@ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract RebaseTokenPool is TokenPool {
    constructor(
        IERC20 _token,
        address[] memory _allowlist,
        address _rmnProxy,
        address _router
    ) TokenPool(_token, 18, _allowlist, _rmnProxy, _router) {}

    function lockOrBurn(
        Pool.LockOrBurnInV1 calldata lockOrBurnIn
    )
        external
        virtual
        override
        returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut)
    {
        _validateLockOrBurn(lockOrBurnIn);
        // Burn the tokens on the source chain. This returns their userAccumulatedInterest before the tokens were burned (in case all tokens were burned, we don't want to send 0 cross-chain)
        uint256 userInterestRate = IRebaseToken(address(i_token))
            .getUserInterestRate(lockOrBurnIn.originalSender);
        // Why address(this) ?? That's simple bcz it's the way CCIP works(So you actually do a token approval then u send yr token to CCIP and then CCIP will send the token to the token pool)
        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);
        // encode a function call to pass the caller's info to the destination pool and update it
        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
            destPoolData: abi.encode(userInterestRate)
        });
    }

    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external returns (Pool.ReleaseOrMintOutV1 memory) {
        _validateReleaseOrMint(releaseOrMintIn);
        address receiver = releaseOrMintIn.receiver;
        uint256 userInterestRate = abi.decode(
            releaseOrMintIn.sourcePoolData,
            (uint256)
        );
        // Mint rebasing tokens to the receiver on the destination chain
        // This will also mint any interest that has accrued since the last time the user's balance was updated.
        IRebaseToken(address(i_token)).mint(
            receiver,
            releaseOrMintIn.amount,
            userInterestRate
        );

        return
            Pool.ReleaseOrMintOutV1({
                destinationAmount: releaseOrMintIn.amount
            });
    }
}
