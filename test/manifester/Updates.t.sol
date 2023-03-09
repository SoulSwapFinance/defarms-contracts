// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract UpdatesTest is Test, Setup {

    function testUpdateFactory() public {
        vm.startPrank(SOUL_DAO_ADDRESS);

        address factory_0 = address(manifester.SoulSwapFactory());
        // console.log('factory_0: %s', factory_0);
        manifester.updateFactory(address(0xbae));
        vm.stopPrank();
        address factory_1 = address(manifester.SoulSwapFactory());
        // console.log('factory_1: %s', factory_1);
        assertFalse(factory_0 == factory_1);
        console.log('[+] factory updated successfully.');

        vm.startPrank(address(0xbae));
        // reverts: when the caller is not the soulDAO address
        vm.expectRevert();
        manifester.updateFactory(factory_0);
        vm.stopPrank();
        console.log('[+] factory update reverts when caller is not soulDAO (as expected).');
    }
}
