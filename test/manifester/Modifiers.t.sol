// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract ModifiersTest is Test, Setup {

    function testWhileActive() public {
        bool isPaused_0 = manifester.isPaused();
        manifester.togglePause(!isPaused_0);
        bool isPaused_1 = manifester.isPaused();
        // console.log('0: %s, 1: %s', isPaused_0, isPaused_1);
        assertTrue(isPaused_0 != isPaused_1);
        console.log('[+] pause state updated successfully.');
    }
}
