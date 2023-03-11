// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract UpdatesTest is Test, Setup {
    // [toggleActive]
    function testToggleActive() public {
        bool isActive_0 = manifestation.isActive();
        // console.log('isActive(0)', isActive_0);
        // toggles: active state.
        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.toggleActiveOverride(!isActive_0);
        bool isActive_1 = manifestation.isActive();
        // console.log('isActive(1)', isActive_1);
        // expects: active states updated.
        assertTrue(isActive_0 != isActive_1);
        console.log('[+] active state updated successfully.');
        vm.stopPrank();

        // expects: non-DAO to revert when toggles active.
        vm.startPrank(address(0xbae));
        vm.expectRevert();
        manifestation.toggleActiveOverride(!isActive_0);
        vm.stopPrank();
        console.log('[+] active state failed to update when not DAO (as expected).');
    }

    // [toggleSettable]
    function testToggleSettable() public {
        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.toggleSettable(false);
        vm.stopPrank();
        vm.startPrank(DAO_ADDRESS);
        vm.expectRevert();
        manifestation.toggleActiveOverride(false);
        vm.expectRevert();
        manifestation.setFeeDaysOverride(12);
        vm.stopPrank();
        console.log('[+] reverts when DAO transacts on non-settable functions (as expected).');
    }

    function testSetDAO() public {
        vm.startPrank(DAO_ADDRESS);
        manifestation.setDAO(address(0xbae));
        vm.stopPrank();
        vm.expectRevert();
        manifestation.setDAO(address(this));
        console.log('[+] only DAO may set DAO.');
    }

    function testSetSoulDAO() public {
        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.setSoulDAO(address(0xbae));
        vm.stopPrank();
        vm.expectRevert();
        manifestation.setSoulDAO(address(this));
        console.log('[+] only soulDAO may set soulDAO.');
    }

    function testLogoURI() public {
        // console.log("logoURI: %s", manifestation.logoURI());
        vm.prank(SOUL_DAO_ADDRESS);
        string memory logoURI = "https://raw.githubusercontent.com/soulswapfinance/assets/prod/blockchains/fantom/assets/0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07/logo.png";
        manifestation.setLogoURI('https://raw.githubusercontent.com/soulswapfinance/assets/prod/blockchains/fantom/assets/0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07/logo.png');
        string memory _logoURI = manifestation.logoURI();
        // console.log("logoURI: %s", manifestation.logoURI());
        assertEq(logoURI, _logoURI);
        console.log("[+] updated logoURI successfully.");
    }

    function testSetFeeDays() public {
        uint maxFeeDays = 30;
        uint minFeeDays = 0;

        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.setFeeDaysOverride(maxFeeDays);
        vm.stopPrank();

        assertEq(maxFeeDays, fromWei(manifestation.feeDays()));
        console.log('[+] feeDays set to %s days.', maxFeeDays);

        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.setFeeDaysOverride(minFeeDays);
        vm.stopPrank();

        assertEq(minFeeDays, fromWei(manifestation.feeDays()));
        console.log('[+] feeDays set to %s days.', minFeeDays);

        vm.startPrank(SOUL_DAO_ADDRESS);
        vm.expectRevert();
        manifestation.setFeeDaysOverride(maxFeeDays + 1);
        vm.stopPrank();
        console.log('[+] reverts when fee days exceeds the max of %s days (as expected).', maxFeeDays);

        vm.startPrank(DAO_ADDRESS);
        vm.expectRevert();
        manifestation.setFeeDaysOverride(maxFeeDays);
        vm.stopPrank();
        console.log('[+] reverts when non-SoulDAO updates fee days (as expected).');
    }

    function testSetNativePair() public {
        address _assetAddress_0 = manifestation.wnativeAddress();
        address _assetAddress_1 = manifestation.usdcAddress();
        bool _isNative_0 = true;
        bool _isNative_1 = false;

        bool isNative_0 = manifestation.isNativePair();
        address assetAddress_0 = manifestation.assetAddress();
        assertEq(isNative_0, _isNative_0);
        assertEq(assetAddress_0, _assetAddress_0);

        // updates native pair to false.
        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.setNativePair(false);
        vm.stopPrank();

        // updates native pair to false (should revert).
        vm.startPrank(address(0xbae));
        vm.expectRevert();
        manifestation.setNativePair(false);
        vm.stopPrank();
        console.log('[+] reverts when non-SouDAO calls setNativePair (as expected).');

        bool isNative_1 = manifestation.isNativePair();
        address assetAddress_1 = manifestation.assetAddress();
        assertEq(isNative_1, _isNative_1);
        console.log('[+] isNativePair updated successfully.');
        assertEq(assetAddress_1, _assetAddress_1);
        console.log('[+] assetAddress updated successfully.');
    }

    function testEmergencyState() public {
        bool ON = true;
        bool OFF = false;

        bool _isActive_0 = ON;
        bool _isEmergency_0 = OFF;
        bool _isReclaimable_0 = OFF;

        bool _isActive_1 = OFF;
        bool _isEmergency_1 = ON;
        // bool _isReclaimable_1 = OFF;

        bool isActive_0 = manifestation.isActive();
        bool isEmergency_0 = manifestation.isEmergency();
        bool isReclaimable_0 = manifestation.isReclaimable();
        // console.log('isActive_0: %s', isActive_0);
        assertEq(isActive_0, _isActive_0);
        assertEq(isEmergency_0, _isEmergency_0);
        assertEq(isReclaimable_0, _isReclaimable_0);

        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.toggleActiveOverride(OFF);
        vm.stopPrank();

        bool isActive_1 = manifestation.isActive();
        bool isEmergency_1 = manifestation.isEmergency();
        bool isReclaimable_1 = manifestation.isReclaimable();

        assertEq(isActive_1, _isActive_1);
        console.log('[+] active state updated successfully.');

        assertEq(isEmergency_1, _isEmergency_1);
        console.log('[+] emergency state updated successfully.');
        
        assertEq(isReclaimable_0, isReclaimable_1);
        console.log('[+] reclaimable state not updated (as expected).');
    }
}
