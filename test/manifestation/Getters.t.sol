// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;
import "../setup/Setup.t.sol";

contract GettersTest is Test, Setup {

    // function _getTVL() internal view returns (uint _TVL) {
    //     _TVL = manifestation.getTVL();
    // }

    // function _getPricePerToken() internal view returns (uint _price) {
    //     _price = manifestation.getPricePerToken();
    // }

    function _deposit(uint _amount) internal {
        manifestation.deposit(_amount);
    }

    // [multiplier] tests: TVL accuracy.
    function testMultiplier() public {
        (uint _from, uint _to) = (100, 400);
        // uint TO = 400;
        uint _multiplier = _to - _from;
        uint multiplier = manifestation.getMultiplier(_from, _to);
        // console.log('multiplier: %s', multiplier);
        assertEq(multiplier, _multiplier);
    }

    // [TVL] tests: TVL accuracy.
    // function testTVL() public {
    //     _deposit(toWei(100));
    //     uint TVL = manifestation.getTVL();
    //     console.log('TVL: %s', TVL);
    // }

    // [price] tests: pricePerToken accuracy.
    function testPricePerToken() public {}

    // [fee] tests: feeRate accuracy.
    function testFeeRate() public {
        uint deltaDays = 10;
        uint _feeRate = (FEE_DAYS - deltaDays) * 1E18;

        uint feeRate = manifestation.getFeeRate(deltaDays);
        // console.log('feeRate: %s', feeRate);
        // console.log('_feeRate: %s', _feeRate);
        assertEq(feeRate, _feeRate);
        console.log('[+] feeRate reported accurately.');
    }

    // [rewardPeriod] tests: reward period accuracy.
    function testRewardPeriod() public {
        (uint startTime, uint endTime) = manifestation.getRewardPeriod();
        uint rewardPeriod = (endTime - startTime) / 1 days;
        // console.log('startTime: %s', startTime);
        // console.log('endTime: %s', endTime);
        // console.log('rewardPeriod: %s', rewardPeriod);
        assertEq(rewardPeriod, DURA_DAYS);
        console.log('[+] set reward period to: %s days successfully.', rewardPeriod);
    }

    function testTotalDeposit() public {
        _deposit(toWei(100));
        // warps to: Day 2.
        vm.warp(2 days);
        _deposit(toWei(200));
        uint _totalDeposit = toWei(300);
        uint totalDeposit = manifestation.getTotalDeposit();
        // console.log('totalDeposit: %s', fromWei(totalDeposit));
        assertEq(totalDeposit, _totalDeposit);
        console.log('[+] total deposit reported accurately.');
    }
    
    function testPendingRewards() public {
        uint depositAmount = toWei(100);
        _deposit(depositAmount);
        // warps to: Day 2.
        vm.warp(1 days);
        // sets: daily rewards to just 1 less that actual (100).
        uint dailyRewards = 99;
        // uint _pendingRewards = toWei(300);
        uint pendingRewards = fromWei(manifestation.getPendingRewards(address(this)));
        // console.log('dailyRewards: %s', dailyRewards);
        // console.log('pendingRewards: %s', pendingRewards);
        assertEq(pendingRewards, dailyRewards);
        console.log('[+] pending rewards (24H) reported accurately.');
    }

    function testGetWithdrawable() public {
        uint _timeDelta = 1 days;
        uint _amount = toWei(100);
        uint deltaDays = manifestation.getDeltaDays(_timeDelta);
        (uint feeAmount, uint withdrawableAmount) = manifestation.getWithdrawable(deltaDays, _amount);
        console.log('feeAmount: %s', fromWei(feeAmount));
        console.log('withdrawableAmount: %s', fromWei(withdrawableAmount));
        bool equalsAmount = feeAmount + withdrawableAmount == _amount;
        assertTrue(equalsAmount);
        console.log('[+] feeAmount + withdrawableAmount = 100% of the withdrawal amount.');
    }
}