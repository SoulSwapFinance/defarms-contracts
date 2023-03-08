// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../src/forge/Script.sol";
import "../src/mocks/MockToken.sol";

contract TokenScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        MockToken rewardToken = new MockToken(
            "RewardToken",
            "REWARD",
            1_000_000
        );

        // silences warning.
        rewardToken;

        vm.stopBroadcast();
    }
}
