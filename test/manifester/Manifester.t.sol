// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract ManifesterTest is Test, Setup {

    // internal functions //
    // updates: given enchanter status (by id).
    function _updateEnchanterStatus(uint id, bool isActive) internal {
        manifester.updateEnchanter(id, isActive);
    }

    // [mInfo]: Addresses (manifestation, dao, asset, deposit, reward)
    function testInfo() public virtual {
        uint id = 0;

        address mAddress = manifester.manifestations(id);
        // address assetAddress = address(WNATIVE);
        address depositAddress = address(DEPOSIT);
        address rewardAddress = address(REWARD);
        address enchanterAddress = ENCHANTRESS_ADDRESS;

         // manifestation address //
        (       address _mAddress         ,,,,)       = manifester.mInfo(id);
         // asset address //
        // (,      address _assetAddress     ,,,,)        = manifester.mInfo(id);
        // deposit address //
        (,     address _depositAddress   ,,,)         = manifester.mInfo(id);
        // reward address //
        (,,    address _rewardAddress    ,,)          = manifester.mInfo(id);
        // creator address //
        (,,,   address _creatorAddress   ,)           = manifester.mInfo(id);
        // enchanter address //
        (,,,,  address _enchanterAddress )            = manifester.mInfo(id);

        // verifies: assetAddress
        // assertEq(_assetAddress, assetAddress, "ok");
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

    // [enchanters] tests: Enchanter Address Accuracy & Checks.
    function testEnchanterAddresses() public {
        (address enchanter_0, ) = manifester.eInfo(0);
        
        // proves: this contract is enchanter[0].
        assertEq(enchanter_0, ENCHANTRESS_ADDRESS);
        console.log('[+] enchanter[0] address is valid.');

        // adds: new (unique) address to enchanters.
        vm.startPrank(SOUL_DAO_ADDRESS);
        manifester.addEnchanter(address(0xbae));
        vm.stopPrank();
        (address enchanter_1, ) = manifester.eInfo(1);
        assertEq(enchanter_1, address(0xbae));
        console.log('[+] adding unique enchanter[1] succeeded.');

        // reverts: when adding duplicate address.
        vm.expectRevert();
        manifester.addEnchanter(ENCHANTRESS_ADDRESS);
        console.log('[+] adding duplicate enchanter[0] reverted (as expected).');
    }

    // [enchanters] tests: Enchanter Status Accuracy & Updates.
    function testEnchanterStatuses() public {
        vm.startPrank(SOUL_DAO_ADDRESS);
        // adds: enchanter[1]
        manifester.addEnchanter(address(0xee));

        // expects: both addresses to be enchanted.
        assertTrue(manifester.enchanted(ENCHANTRESS_ADDRESS));
        // console.log('[+] enchanted[0] status verified.');
        assertTrue(manifester.enchanted(address(0xee)));
        // console.log('[+] enchanted[1] status verified.');
        console.log('[+] enchanted[0, 1] statuses verified.');

        // updates: enchanters[0, 1] to false.
        _updateEnchanterStatus(0, false);
        _updateEnchanterStatus(1, false);
        (, bool _status_0) = manifester.eInfo(0);
        (, bool _status_1) = manifester.eInfo(1);

        // expects: enchanters[0, 1] to be false.
        assertFalse(_status_0);
        // console.log('[+] enchanter[0] status updated to: %s.', _status_0);
        assertFalse(_status_1);
        assertEq(_status_0, _status_1);
        // console.log('[+] enchanter[1] status updated to: %s.', _status_1);
        console.log('[+] enchanter[0, 1] statuses updated to: %s.', _status_0);

        // updates: enchanters[0, 1] to true.
        _updateEnchanterStatus(0, true);
        _updateEnchanterStatus(1, true);
        (, bool status_0_) = manifester.eInfo(0);
        (, bool status_1_) = manifester.eInfo(1);

        vm.stopPrank();

        // expects: enchanters[0, 1] to be false.
        assertTrue(status_0_);
        // console.log('[+] enchanter[0] status updated to: %s.', status_0_);
        assertTrue(status_1_);
        // console.log('[+] enchanter[1] status updated to: %s.', status_1_);
        assertEq(status_0_, status_1_);
        console.log('[+] enchanter[0, 1] statuses updated to: %s.', status_0_);
    }
}