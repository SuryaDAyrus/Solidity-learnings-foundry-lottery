// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
// import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig
            .getConfigByChainId(block.chainid)
            .vrfCoordinator;
        // address account = helperConfig.getConfigByChainId(block.chainid).account;
        // return createSubscription(vrfCoordinatorV2_5, account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        console.log("Your subscription Id is: ", subId);
        return (subId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    )
        public
        returns (
            // address account
            address,
            address
        )
    {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (account, vrfCoordinator);
    }
}

contract FundSubscription is CodeConstants, Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 _subscriptionId = helperConfig.getConfig()._subscriptionId;
        address linkToken = helperConfig.getConfig().link;

        // ✅ Auto-create subscription if needed
        if (_subscriptionId == 0) {
            console.log("No subscription found, creating one...");
            vm.startBroadcast();
            _subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator)
                .createSubscription();
            vm.stopBroadcast();
            console.log("New subscription created with ID:", _subscriptionId);
        }

        fundSubscription(vrfCoordinator, _subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 _subscriptionId,
        address link
    ) public {
        console.log("Funding subscription on chainId: ", _subscriptionId);
        console.log("using vrfCoordinator: ", vrfCoordinator);
        console.log(" on chainId: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            console.log(
                "You are funding a subscription on a local chain, assuming you have the mocks deployed and the subscription created"
            );
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                _subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(_subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentDeployment) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint64 subId = helperConfig.getConfig()._subscriptionId;
        addConsumer(mostRecentDeployment, subId, vrfCoordinator);
    }

    function addConsumer(
        address mostRecentDeployment,
        uint64 subId,
        address vrfCoordinator
    ) public {
        console.log(
            "Adding consumer to subscription on contract: ",
            mostRecentDeployment
        );
        console.log(
            "Adding consumer to subscription on chainId: ",
            block.chainid
        );
        console.log("Adding consumer to vrfCoordinator: ", vrfCoordinator);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            mostRecentDeployment
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentDeployment);
    }
}
