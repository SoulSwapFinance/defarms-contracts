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

    // [userInfo] tests: UserInfo Accuracy.
    function testUserInfo() public {
        uint _amount = toWei(100);
        uint _depositTime = 1 days; 

        // warps to Day One, then deposit 100 DEPOSIT.
        vm.warp(1 days);
        manifestation.deposit(_amount);

        (address mAddress, uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) = manifester.getUserInfo(0, address(this)); // id, account.
        // console.log('mAddress: %s, amount: %s, rewardDebt: %s', mAddress, amount, rewardDebt);
        // console.log('depositTime: %s, withdrawTime: %s, timeDelta: %s', depositTime, withdrawTime, timeDelta);
        // console.log('deltaDays: %s', deltaDays);
        assertEq(mAddress, MANIFESTATION_0_ADDRESS);
        assertEq(amount, _amount);
        assertEq(rewardDebt, 0);
        assertEq(withdrawTime, 0);
        assertEq(depositTime, _depositTime);
        assertEq(timeDelta, 0);
        assertEq(deltaDays, 0);
        console.log('[+] user info reported accurately.');
    }

    // function testInfo() public {
        // (address mAddress,
        // address daoAddress,

        // string memory name, 
        // string memory symbol, 
        // string memory logoURI,

        // address rewardAddress,
        // address depositAddress,

        // uint rewardPerSecond,
        // uint rewardRemaining,
        // uint startTime,
        // uint endTime,
        // uint dailyReward, 
        // uint feeDays) = manifester.getInfo(0); // id

        // console.log('mAddress: %s, daoAddress: %s', mAddress, daoAddress);
        // console.log('rewardAddress: %s, depositAddress: %s', rewardAddress, depositAddress);
        // console.log('name: %s, symbol: %s, logoURI: %s', name, symbol, logoURI);
        // console.log('rewardPerSecond: %s, rewardRemaining: %s', rewardPerSecond, rewardRemaining);
        // console.log('startTime: %s, endTime: %s', startTime, endTime);
        // console.log('dailyReward: %s, dailyReward: %s, feeDays: %s', dailyReward, dailyReward, feeDays);
    // }

}
