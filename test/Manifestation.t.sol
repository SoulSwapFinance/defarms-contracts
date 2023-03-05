// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./setup/Setup.t.sol";
import './Manifester.t.sol';

contract ManifestationTest is Test, Setup {
    // Manifester manifester = Setup.manifester;

    // [1]: Manifestation Creation
    function testCreation() public virtual {
        // createManifestation();
        address mAddress = manifester.manifestations(0);
        bool actual = mAddress != address(0);
        // expect the address to not be the zero address //
        assertTrue(actual);
        // console.log("[+] mAddress: %s", mAddress);
    }

}
