// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Vault} from "src/Vault.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {RebaseTokenPool} from "src/RebaseTokenPool.sol";

import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract TokenAndPoolDeployer is Script {
    function run() public returns (RebaseToken token, RebaseTokenPool pool) {
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory tokenNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        // first deploy the token then the pool in ccip way
        vm.startBroadcast();
        token = new RebaseToken();
        pool = new RebaseTokenPool(
            IERC20(address(token)),
            new address[](0),
            tokenNetworkDetails.rmnProxyAddress,
            tokenNetworkDetails.routerAddress
        );
        vm.stopBroadcast();
        return (token, pool);
    }
}

contract SetRole is Script {
    function run(address _rebaseToken, address _rebaseTokenPool) public {
        grantRole(_rebaseToken, _rebaseTokenPool);
    }

    function grantRole(address token, address pool) public {
        vm.startBroadcast();
        IRebaseToken(token).grantMintAndBurnRole(address(pool));
        vm.stopBroadcast();
    }
}

contract SetAdmin is Script {
    function run(address token) public {
        setRegistryOwner(token);
    }

    function setRegistryOwner(address token) public {
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory tokenNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startBroadcast();
        RegistryModuleOwnerCustom(tokenNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(token)
        );
        vm.stopBroadcast();
    }
}

contract SetTokenAdmin is Script {
    function run(address token) public {
        setTokenAdminSetRole(token);
    }

    function setTokenAdminSetRole(address token) public {
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory tokenNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startBroadcast();
        TokenAdminRegistry(tokenNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(token));
        vm.stopBroadcast();
    }
}

contract SetTokenAdminSetPool is Script {
    function run(address token, address pool) public {
        setTokenAdminSetPool(token, pool);
    }

    function setTokenAdminSetPool(address token, address pool) public {
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory tokenNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startBroadcast();
        TokenAdminRegistry(tokenNetworkDetails.tokenAdminRegistryAddress).setPool(address(token), address(pool));
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
