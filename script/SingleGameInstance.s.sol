// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "../src/GameManager.sol";

contract SingleGameInstanceScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        GameManager gameInstance = new GameManager(10, 4, 10, false);

        vm.stopBroadcast();
    }
}
