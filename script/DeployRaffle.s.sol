// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external {}

        function deployContract() public returns (Raffle, HelperConfig) {
              HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
              HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

              vm.startBroadcast();
                Raffle raffle = new Raffle(
                    config.entranceFee,
                    config.interval,
                    config.vrfCoordinator,
                    config.gasLane,
                    config._subscriptionId,
                    config.callbackGasLimit
                );

              vm.stopBroadcast();

              return (raffle, helperConfig);
        }
        
    
}