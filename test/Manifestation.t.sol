// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./setup/c.t.sol";
import './Manifester.t.sol';

contract ManifestationTest is Test, c {

    // creates: New Manifestation
    function createManifestation() public virtual {
        c.manifester.createManifestation(
            c.DEPOSIT_ADDRESS,      // address depositAddress,
            c.REWARD_ADDRESS,       // address rewardAddress, 
            c.DAO_ADDRESS,         // address daoAddress,
            c.DURA_DAYS,           // uint duraDays, 
            c.FEE_DAYS,            // uint feeDays, 
            c.DAILY_REWARD,        // uint dailyReward
            true                  // bool isNative
        );

        address mAddress = c.manifester.manifestations(0);
        c.manifestation = Manifestation(mAddress);
    }

    // [1]: Manifestation Creation
    function testCreation() public virtual {
        createManifestation();
        address mAddress = c.manifester.manifestations(0);
        bool actual = mAddress != address(0);
        // expect the address to not be the zero address //
        assertTrue(actual);
        // console.log("[+] mAddress: %s", mAddress);
    }

}
