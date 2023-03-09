// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract GettersTest is Test, Setup {

    function _getSacrifice(uint _totalRewards) internal view returns (uint _sacrifice) {
        _sacrifice = manifester.getSacrifice(_totalRewards) / 1E18;
    }

    function _getSplit(uint _sacrifice) internal view returns (uint _toDAO, uint _toEnchanter) {
        (_toDAO, _toEnchanter ) = manifester.getSplit(_sacrifice);
    }

    // [sacrifice] tests: Sacrifice Accuracy.
    function testSacrifice() public {
        uint totalRewards = 100_000;
        uint expected = 5_000;
        uint actual = _getSacrifice(totalRewards);
        // console.log('expected: %s, actuals: %s', expected, actual);
        assertEq(actual, expected, "ok");
        // console.log("[+] getSacrifice(100K): %s", actual);
    }

}
