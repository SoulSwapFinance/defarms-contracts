// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./setup/Setup.t.sol";

contract ManifesterTest is Test, Setup {

    function _addEnchanter(address account, string memory proof) internal {
        manifester.addEnchanter(account, proof);
    }

    /*/ CONTRACT TESTS /*/

    // [mInfo]: Addresses (manifestation, dao, asset, deposit, reward)
    function testInfo() public virtual {
        uint id = 0;
        // initializeManifestation(id);

        address mAddress = manifester.manifestations(id);
        address assetAddress = address(wnativeToken);
        address depositAddress = address(nativePair);
        address rewardAddress = address(rewardToken);
        address enchanterAddress = 0xFd63Bf84471Bc55DD9A83fdFA293CCBD27e1F4C8;

         // manifestation address //
        (       address _mAddress       ,,,,,)    = manifester.mInfo(id);
         // asset address //
        (,      address _assetAddress  ,,,,)   = manifester.mInfo(id);
        // deposit address //
        (,,     address _depositAddress   ,,,)      = manifester.mInfo(id);
        // reward address //
        (,,,    address _rewardAddress ,,)       = manifester.mInfo(id);
        // creator address //
        (,,,,    address _creatorAddress ,)       = manifester.mInfo(id);
        // enchanter address //
        (,,,,,    address _enchanterAddress)       = manifester.mInfo(id);

        // verifies: assetAddress
        assertEq(_assetAddress, assetAddress, "ok");
        // console.log("[+] assetAddress: %s", assetAddress);

        // verifies: depositAddress
        assertEq(_depositAddress, depositAddress, "ok");
        // console.log("[+] depositAddress: %s", depositAddress);

        // verifies: rewardAddress
        assertEq(_rewardAddress, rewardAddress, "ok");
        // console.log("[+] rewardAddress: %s", rewardAddress);

        // verifies: creatorAddress
        assertEq(_creatorAddress, CREATOR_ADDRESS, "ok");
        // console.log("[+] daoAddress: %s", DAO_ADDRESS);

        // verifies: mAddress
        assertEq(_mAddress, mAddress, "ok");
        // console.log("[+] mAddress: %s", mAddress);
       
        // verifies: enchanterAddress
        assertEq(_enchanterAddress, enchanterAddress, "ok");
        // console.log("[+] enchanterAddress: %s", enchanterAddress);
    }

    // [nativePair] test: Native Pair
    function testPairs() public {
        bool _isNative_Native = nativePair.isNative();
        bool _isNative_Stable = stablePair.isNative();
        
        bool isNative_Native = true;
        bool isNative_Stable = false;

        assertEq(_isNative_Native, isNative_Native, "ok");
        assertEq(_isNative_Stable, isNative_Stable, "ok");

        // console.log("[+] isNative(nativePair): %s", nativePair.isNative());
        // console.log("[+] isNative(stablePair): %s", stablePair.isNative());

        // console.log("[+] nativePair: %s", address(nativePair));
        // console.log("[+] stablePair: %s", address(stablePair));
    }

    // [sacrifice] tests: Sacrifice Accuracy
    function testSacrifice() public {
        uint totalRewards = 100_000;
        uint expected = 2_000;
        uint actual = manifester.getSacrifice(totalRewards) / 1E18;
        // console.log('expected: %s, actuals: %s', expected, actual);
        assertEq(actual, expected, "ok");
        // console.log("[+] getSacrifice(100K): %s", actual);
    }

    // [enchanters] tests: Enchanter Address Accuracy
    function testEnchanters() public {
        address _enchanterAddress = address(this);
        _addEnchanter(_enchanterAddress, 'test');
        (address enchanterAddress,,) = manifester.eInfo(1);
        assertEq(enchanterAddress, _enchanterAddress);
    }

}
