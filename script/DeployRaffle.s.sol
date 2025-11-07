// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer } from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external 
    {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (block.chainid == 0) {
            // create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (address account, address vrfCoordinator) = createSubscription.createSubscription(
                config.account,
                config.vrfCoordinator
            );
            // config._subscriptionId = subId;

            // fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config._subscriptionId, config.link);
        }

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

        AddConsumer addConsumers = new AddConsumer();
        addConsumers.addConsumer(
            config.vrfCoordinator,
            config._subscriptionId,
            address(raffle)
        );
        return (raffle, helperConfig);
    }
}
