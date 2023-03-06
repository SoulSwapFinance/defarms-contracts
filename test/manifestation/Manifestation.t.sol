// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import '../manifester/Manifester.t.sol';

contract ManifestationTest is Test, Setup {

    function _getStrings() internal view returns (
        string memory name,
        string memory symbol,
        string memory logoURI,
        string memory assetSymbol
    ) {
        name = manifestation.name();
        symbol = manifestation.symbol();
        logoURI = manifestation.logoURI();
        assetSymbol = manifestation.assetSymbol();
    }

    // [creation]: Manifestation Creation.
    function testCreation() public {
        // createManifestation();
        address mAddress = manifester.manifestations(0);
        bool actual = mAddress != address(0);
        // expect the address to not be the zero address //
        assertTrue(actual);
        // console.log("[+] mAddress: %s", mAddress);
    }

    // [strings]: Manifestation Strings.
    function testStrings() public {
        string memory _name = 'Manifest: RewardToken';
        string memory _symbol = 'REWARD-NATIVE MP';
        string memory _logoURI = '';
        string memory _assetSymbol = 'NATIVE';

        (string memory name, string memory symbol, string memory logoURI, string memory assetSymbol) = _getStrings();

        assertEq(name, _name);
        assertEq(symbol, _symbol);
        assertEq(logoURI, _logoURI);
        assertEq(assetSymbol, _assetSymbol);
    }
}
