// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RegistryModuleOwnerCustom} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract TokenAndPoolDeployer is Script {
    function run() public returns (RebaseToken rbt, RebaseTokenPool rbtPool) {
        CCIPLocalSimulatorFork ccip = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory netWorkDetails = ccip.getNetworkDetails(
            block.chainid
        );
        vm.startBroadcast();
        rbt = new RebaseToken();
        rbtPool = new RebaseTokenPool(
            IERC20(address(rbt)),
            new address[](0),
            netWorkDetails.rmnProxyAddress,
            netWorkDetails.routerAddress
        );
        rbt.grantMintAndBurnRole(address(rbtPool));
        RegistryModuleOwnerCustom(
            netWorkDetails.registryModuleOwnerCustomAddress
        ).registerAdminViaOwner(address(rbt));
        TokenAdminRegistry(netWorkDetails.tokenAdminRegistryAddress)
            .acceptAdminRole(address(rbt));
        TokenAdminRegistry(netWorkDetails.tokenAdminRegistryAddress).setPool(
            address(rbt),
            address(rbtPool)
        );
        vm.stopBroadcast();
    }
}

contract VaultDeployer is Script {
    function run(address _rebaseToken) public returns (Vault vault) {
        vm.startBroadcast();
        vault = new Vault(IRebaseToken(_rebaseToken));
        IRebaseToken(_rebaseToken).grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
    }
}
