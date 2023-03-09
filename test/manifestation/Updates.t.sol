// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract UpdatesTest is Test, Setup {
    // [toggleActive]
    function testToggleActive() public {
        bool isActive_0 = manifestation.isActivated();
        // console.log('isActive(0)', isActive_0);
        // toggles: active state.
        vm.startPrank(DAO_ADDRESS);
        manifestation.toggleActive(!isActive_0);
        bool isActive_1 = manifestation.isActivated();
        // console.log('isActive(1)', isActive_1);
        // expects: active states updated.
        assertTrue(isActive_0 != isActive_1);
        console.log('[+] active state updated successfully.');
        vm.stopPrank();

        // expects: non-DAO to revert when toggles active.
        vm.startPrank(address(0xbae));
        vm.expectRevert();
        manifestation.toggleActive(!isActive_0);
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
        manifestation.toggleEmergency(true);
        vm.expectRevert();
        manifestation.toggleActive(false);
        vm.expectRevert();
        manifestation.setFeeDays(12);
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

        vm.startPrank(DAO_ADDRESS);
        manifestation.setFeeDays(maxFeeDays);
        vm.stopPrank();

        assertEq(maxFeeDays, fromWei(manifestation.feeDays()));
        console.log('[+] feeDays set to %s days.', maxFeeDays);

        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.setFeeDaysOverride(minFeeDays);
        vm.stopPrank();

        assertEq(minFeeDays, fromWei(manifestation.feeDays()));
        console.log('[+] feeDays set to %s days.', minFeeDays);

        vm.startPrank(DAO_ADDRESS);
        vm.expectRevert();
        manifestation.setFeeDays(maxFeeDays + 1);
        vm.stopPrank();
        console.log('[+] reverts when fee days exceeds the max of %s days (as expected).', maxFeeDays);

        vm.startPrank(SOUL_DAO_ADDRESS);
        vm.expectRevert();
        manifestation.setFeeDays(maxFeeDays);
        vm.stopPrank();
        console.log('[+] reverts when non-DAO updates fee days (as expected).');
    }


}
