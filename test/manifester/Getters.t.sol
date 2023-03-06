// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract GettersTest is Test, Setup {

    function _getSacrifice(uint _totalRewards) internal view returns (uint _sacrifice) {
        _sacrifice = manifester.getSacrifice(_totalRewards) / 1E18;
    }

    function _getShare() internal view returns (uint _share) {
        _share = manifester.eShare();
    }

    function _getSplit(uint _sacrifice) internal view returns (uint _toDAO, uint _toEnchanter) {
        (_toDAO, _toEnchanter ) = manifester.getSplit(_sacrifice);
    }

    // [sacrifice] tests: Sacrifice Accuracy.
    function testGetSacrifice() public {
        uint totalRewards = 100_000;
        uint expected = 2_000;
        uint actual = _getSacrifice(totalRewards);
        // console.log('expected: %s, actuals: %s', expected, actual);
        assertEq(actual, expected, "ok");
        // console.log("[+] getSacrifice(100K): %s", actual);
    }

    function testGetSplit() public {
        uint _eShare = _getShare();
        uint sacrifice = 1_000;
        uint toDAO = 20 * 1E18;
        uint toEnchanter = 10 * 1E18;

        console.log('eShare: %s%', _eShare / 1E18);
        ( uint _toDAO, uint _toEnchanter ) = _getSplit(sacrifice);
        console.log('DAO: %s REWARD', _toDAO / 1E18);
        console.log('Enchanter: %s REWARD', _toEnchanter / 1E18);

        assertEq(_toDAO, toDAO);
        assertEq(_toEnchanter, toEnchanter);
    }

}
