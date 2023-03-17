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

    function testUpdateAuraSettings() public {
        address auraAddress_0 = manifester.auraAddress();
        uint auraMinimum_0 = manifester.auraMinimum();

        vm.startPrank(SOUL_DAO_ADDRESS);
        manifester.updateAuraAddress(address(0xbabe));
        address auraAddress_1 = manifester.auraAddress();
        // console.log('auraAddress: %s', auraAddress_1);
        vm.stopPrank();

        vm.startPrank(SOUL_DAO_ADDRESS);
        manifester.updateAuraMinimum(toWei(100));
        uint auraMinimum_1 = manifester.auraMinimum();
        // console.log('auraMinimum: %s', fromWei(auraMinimum_1));
        vm.stopPrank();

        assertTrue(auraAddress_1 != address(0));
        console.log('[+] updated auraAddress successfully.');
        assertFalse(auraAddress_0 == auraAddress_1);
        assertFalse(auraMinimum_0 == auraMinimum_1);
        console.log('[+] updated auraMinimum successfully.');
    }

    function testUpdateSacrifice() public {
        uint sacrifice_0 = manifester.bloodSacrifice();
        vm.startPrank(SOUL_DAO_ADDRESS);
        manifester.updateSacrifice(10);
        vm.stopPrank();

        uint sacrifice_1 = manifester.bloodSacrifice();
        // console.log('sacrifice_0: %s%', fromWei(sacrifice_0));
        // console.log('sacrifice_1: %s%', fromWei(sacrifice_1));
        assertFalse(sacrifice_0 == sacrifice_1);
        console.log('[+] sacrifice updated successfully.');
    }

    function testUpdateAura() public {
        uint _auraMinimum = toWei(100);
        address _auraAddress = address(0xeaeaea);
        uint auraMinimum_0 = manifester.auraMinimum();
        address auraAddress_0 = manifester.auraAddress();
        // console.log('min0. %s', manifester.auraMinimum());
        // console.log('aura0. %s', manifester.auraAddress());

        // update auraMinimum //
        vm.expectRevert();
        manifester.updateAuraMinimum(_auraMinimum);
        console.log('[+] reverts when non-soulDAO updates aura minimum');

        vm.prank(SOUL_DAO_ADDRESS);
        manifester.updateAuraMinimum(_auraMinimum);
        vm.stopPrank();

        uint auraMinimum_1 = manifester.auraMinimum();
        assertTrue(_auraMinimum == auraMinimum_1 && auraMinimum_0 != auraMinimum_1);
        console.log('[+] auraMinimum updated successfully.');

        // update auraAddress //
        vm.expectRevert();
        manifester.updateAuraAddress(_auraAddress);
        console.log('[+] reverts when non-soulDAO updates aura address');

        vm.prank(SOUL_DAO_ADDRESS);
        manifester.updateAuraAddress(_auraAddress);
        vm.stopPrank();

        address auraAddress_1 = manifester.auraAddress();
        assertTrue(_auraAddress == auraAddress_1 && auraAddress_0 != auraAddress_1);
        console.log('[+] auraAddress updated successfully.');

        // console.log('min0. %s', manifester.auraMinimum());
        // console.log('aura0. %s', manifester.auraAddress());

    }
}
