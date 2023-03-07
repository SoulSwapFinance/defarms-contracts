// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract UpdatesTest is Test, Setup {

    function testToggleActive() public {
        bool isActive_0 = manifestation.isActivated();
        // console.log('isActive(0)', isActive_0);
        // toggles: active state.
        manifestation.toggleActive(!isActive_0);
        bool isActive_1 = manifestation.isActivated();
        // console.log('isActive(1)', isActive_1);
        // expects: active states updated.
        assertTrue(isActive_0 != isActive_1);
        console.log('[+] active state updated successfully');
        // expects: non-DAO to revert when toggles active.
        vm.startPrank(address(0xee));
        vm.expectRevert();
        manifestation.toggleActive(!isActive_0);
        vm.stopPrank();
        console.log('[+] active state failed to update when not DAO (as expected)');
    }

    function testSetDAO() public {
        manifestation.setDAO(address(0xee));
        vm.expectRevert();
        manifestation.setDAO(address(this));
        console.log('[+] only DAO may set DAO');
    }

    function testSetSoulDAO() public {
        manifestation.setSoulDAO(address(0xee));
        vm.expectRevert();
        manifestation.setSoulDAO(address(this));
        console.log('[+] only soulDAO may set soulDAO');
    }

    function testLogoURI() public {
        // console.log("logoURI: %s", manifestation.logoURI());
        string memory logoURI = "https://raw.githubusercontent.com/soulswapfinance/assets/prod/blockchains/fantom/assets/0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07/logo.png";
        manifestation.setLogoURI('https://raw.githubusercontent.com/soulswapfinance/assets/prod/blockchains/fantom/assets/0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07/logo.png');
        string memory _logoURI = manifestation.logoURI();
        // console.log("logoURI: %s", manifestation.logoURI());
        assertEq(logoURI, _logoURI);
        console.log("[+] updated logoURI successfully.");
    }
}
