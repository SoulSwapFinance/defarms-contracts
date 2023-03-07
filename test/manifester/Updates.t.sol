// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract UpdatesTest is Test, Setup {

    function testUpdateFactory() public {
        address factory_0 = address(manifester.SoulSwapFactory());
        // console.log('factory_0: %s', factory_0);
        manifester.updateFactory(address(0xee));
        address factory_1 = address(manifester.SoulSwapFactory());
        // console.log('factory_1: %s', factory_1);
        assertFalse(factory_0 == factory_1);
        console.log('[+] factory updated successfully.');

        vm.startPrank(factory_1);
        // reverts: when the caller is not the soulDAO address
        vm.expectRevert();
        manifester.updateFactory(factory_0);
        vm.stopPrank();
        console.log('[+] factory update reverts when caller is not soulDAO (as expected).');
    }
}
