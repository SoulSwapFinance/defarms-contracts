// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../src/forge/Script.sol";
import "../src/Manifestation.sol";

contract ManifestationScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        Manifestation manifestation = new Manifestation();

        // silences warning.
        manifestation;

        vm.stopBroadcast();
    }
}