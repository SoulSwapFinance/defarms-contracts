// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./setup/c.t.sol";
import { DSTest } from "src/forge/DSTest.sol";

contract ManifesterTest is Test, c {

    // creates: New Manifestation
    function createManifestation() public {
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

    function initializeManifestation(uint id) public virtual {
        createManifestation();
        c.manifester.initializeManifestation(id);
    }

    /*/ CONTRACT TESTS /*/
    // 1 // mInfo: 
    // 3 // Native Pair
    // 4 // Stable Pair
    // 5 // Calculate Sacrifice

    // [mInfo]: Manifestation Info (manifestatin, dao)
    function testInfo_Addresses() public virtual {
        uint id = 0;
        initializeManifestation(id);

        address mAddress = c.manifester.manifestations(id);
        address assetAddress = address(c.wnativeToken);
        address depositAddress = address(c.nativePair);
        address rewardAddress = address(c.rewardToken);

         // manifestation address //
        (       address _mAddress       ,,,,,,,)    = c.manifester.mInfo(id);
         // dao address //
        (,,,,   address _daoAddress     ,,,)        = c.manifester.mInfo(id);
         // asset address //
        (,      address _assetAddress  ,,,,,,)   = c.manifester.mInfo(id);
        // deposit address //
        (,,     address _depositAddress   ,,,,,)      = c.manifester.mInfo(id);
        // reward address //
        (,,,    address _rewardAddress ,,,,)       = c.manifester.mInfo(id);

        // verifies: assetAddress
        assertEq(_assetAddress, assetAddress, "ok");
        // console.log("[+] assetAddress: %s", assetAddress);

        // verifies: depositAddress
        assertEq(_depositAddress, depositAddress, "ok");
        // console.log("[+] depositAddress: %s", depositAddress);

        // verifies: rewardAddress
        assertEq(_rewardAddress, rewardAddress, "ok");
        // console.log("[+] rewardAddress: %s", rewardAddress);

        // verifies: daoAddress
        assertEq(_daoAddress, c.DAO_ADDRESS, "ok");
        // console.log("[+] daoAddress: %s", c.DAO_ADDRESS);

        // verifies: mAddress
        assertEq(_mAddress, mAddress, "ok");
        // console.log("[+] mAddress: %s", mAddress);
    }

    // [mInfo]: Manifestation Info (constants)
    function testInfo_Constants() public virtual {
        uint id = 0;
        initializeManifestation(id);

        (,,,,,  uint _duraDays          ,,)         = c.manifester.mInfo(id);
        (,,,,,, uint _feeDays           ,)          = c.manifester.mInfo(id);
        (,,,,,,,uint _dailyReward       )           = c.manifester.mInfo(id);

        // verifies: duraDays
        assertEq(_duraDays, c.DURA_DAYS, "ok");
        // console.log("[+] duraDays: %s", c.DURA_DAYS);

        // verifies: feeDays
        assertEq(_feeDays, c.FEE_DAYS, "ok");
        // console.log("[+] feeDays: %s", c.FEE_DAYS);

        // verifies: dailyReward
        assertEq(_dailyReward, c.DAILY_REWARD, "ok");
        // console.log("[+] dailyReward: %s", c.DAILY_REWARD);
    }

    // [3] test: Native Pair
    function testPairs() public {
        // bool isNative = true;
        // bool _isNative = c.nativePair.isNative();

        bool _isNative_Native = c.nativePair.isNative();
        bool _isNative_Stable = c.stablePair.isNative();
        
        bool isNative_Native = true;
        bool isNative_Stable = false;

        assertEq(_isNative_Native, isNative_Native, "ok");
        assertEq(_isNative_Stable, isNative_Stable, "ok");

        // console.log("[+] isNative(nativePair): %s", c.nativePair.isNative());
        // console.log("[+] isNative(stablePair): %s", c.stablePair.isNative());

        // console.log("[+] nativePair: %s", address(c.nativePair));
        // console.log("[+] stablePair: %s", address(c.stablePair));
    }

    // tests: Sacrifice Accuracy
    function testSacrifice() public {
        uint totalRewards = 100_000;
        uint expected = 1_000;
        uint actual = c.manifester.getSacrifice(totalRewards) / 1E18;
        // console.log('expected: %s, actuals: %s', expected, actual);
        assertEq(actual, expected, "ok");
        // console.log("[+] getSacrifice(100K): %s", actual);
    }

}
