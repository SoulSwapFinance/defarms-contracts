// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "lib/forge-std/src/Script.sol";
import "../src/Manifester.sol";

contract ManifesterScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        Manifester refunder = new Manifester(
            
        );

        vm.stopBroadcast();
    }
}
