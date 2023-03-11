// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import '../setup/Setup.t.sol';

contract ManifestationTest is Test, Setup {

    function _deposit(uint _amount) internal {
        manifestation.deposit(_amount);
    }

    function _withdraw(uint _amount) internal {
        manifestation.withdraw(_amount);
    }

    function _getStrings() internal view returns (
        string memory name,
        string memory symbol,
        string memory logoURI
        // string memory assetSymbol
    ) {
        name = manifestation.name();
        symbol = manifestation.symbol();
        logoURI = manifestation.logoURI();
        // assetSymbol = manifestation.assetSymbol();
    }

    function _userInfo(address _account) internal view returns (uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        (amount, rewardDebt, withdrawTime, depositTime, timeDelta, deltaDays) = manifestation.getUserInfo(_account);
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
        string memory _name = '[0] RewardToken Farm';
        string memory _symbol = 'REWARD';
        string memory _logoURI = 'https://raw.githubusercontent.com/SoulSwapFinance/assets/prod/blockchains/fantom/assets/0xc7183455a4C133Ae270771860664b6B7ec320bB1.logo.png';

        (string memory name, string memory symbol, string memory logoURI) = _getStrings();
        // console.log('depositAddress: %s', manifestation.depositAddress());
        // console.log('logoURI: %s', logoURI);

        assertEq(name, _name);
        assertEq(symbol, _symbol);
        assertEq(logoURI, _logoURI);
        console.log('[+] strings reported accurately.');
    }

    // [deposit]: Deposits 100 tokens.
    function testDeposit() public {
        // address depositToken = manifestation.depositAddress();
        // console.log('my deposit bal: %s', fromWei(DEPOSIT.balanceOf(address(this))));
        // console.log('deposit address: %s', depositToken);
        uint deposited_0 = manifestation.totalDeposited(); 
        uint _depositAmount = toWei(100);
        _deposit(_depositAmount);
        uint deposited_1 = manifestation.totalDeposited(); 
        uint depositAmount = deposited_1 - deposited_0;
        // console.log('deposited amount: %s', fromWei(depositAmount));
        assertEq(depositAmount, _depositAmount);
        console.log('[+] deposited %s successfully', fromWei(depositAmount));
    }

    // [withdraw]: Withdraws 500 tokens (without fee).
    function testWithdraw() public {
        uint amount = toWei(500);
        _deposit(amount);
       
        uint _withdrawAmount = amount;
        uint bal_0_M0 = manifestation.getTotalDeposit();
        _withdraw(_withdrawAmount);
        uint bal_1_M0 = manifestation.totalDeposited();
        uint withdrawAmount = bal_0_M0 - bal_1_M0;
        assertEq(withdrawAmount, _withdrawAmount);
        console.log('[+] withdrew %s from Manifestation successfully (no fee).', fromWei(withdrawAmount));
    }

    // [withdraw-fee]: Withdraws 50 tokens.
    function testWithdrawFee() public {
        uint amount = toWei(500);
        _deposit(amount);
        // uint feeDays = manifestation.feeDays();
        // console.log('feeDays: %s days', fromWei(feeDays));
        vm.warp(2 days);
        // uint timeDelta = manifestation.getUserDelta(address(this));
        // uint deltaDays = manifestation.getDeltaDays(timeDelta);
        // (uint feeAmount, uint withdrawableAmount) = manifestation.getWithdrawable(deltaDays, amount);
        // console.log('timeDelta: %s seconds', timeDelta);
        // console.log('deltaDays: %s days', deltaDays);
        // console.log('feeAmount: %s', fromWei(feeAmount));
        // console.log('withdrawable: %s', fromWei(withdrawableAmount));

        uint _withdrawAmount = amount;
        uint bal_0_M0 = manifestation.totalDeposited();
        uint bal_0_DAO = DEPOSIT.balanceOf(DAO_ADDRESS);
        uint bal_0_USER = DEPOSIT.balanceOf(address(this));

        // withdraws 500 from manifestation.
        _withdraw(_withdrawAmount);
        uint bal_1_M0 = manifestation.totalDeposited();
        uint bal_1_DAO = DEPOSIT.balanceOf(DAO_ADDRESS);
        uint bal_1_USER = DEPOSIT.balanceOf(address(this));

        uint withdrawAmount = bal_0_M0 - bal_1_M0;
        assertEq(withdrawAmount, _withdrawAmount);
        console.log('[+] withdrew %s from Manifestation successfully (with fee).', fromWei(withdrawAmount));
        string memory daoDirection = bal_1_DAO > bal_0_DAO ? '+' : '-';
        string memory userDirection = bal_1_USER > bal_0_USER ? '+' : '-';
        uint toDAO = bal_1_DAO > bal_0_DAO ? bal_1_DAO - bal_0_DAO : bal_0_DAO - bal_1_DAO;
        uint toUSER = bal_1_USER > bal_0_USER ? bal_1_USER - bal_0_USER : bal_0_USER - bal_1_USER;
        uint daoShare = toDAO * 100 / withdrawAmount;
        uint userShare = toUSER * 100 / withdrawAmount;

        assertTrue(daoShare >= 12 && daoShare <= 14);
        console.log('[+] DAO Balance: %s%s (%s%) updated successfully.', daoDirection, fromWei(toDAO), daoShare);

        assertEq(userShare, 87);
        console.log('[+] USER Balance: %s%s (%s%) updated successfully.', userDirection, fromWei(toUSER), userShare);
    }

    function testHarvest() public {
        uint rewardPerSecond = manifestation.rewardPerSecond();
        uint rewardPerDay = fromWei(rewardPerSecond * 1 days);
        // console.log('rewardPerDay: %s', fromWei(rewardPerDay));
        _deposit(toWei(100));
        uint bal_0 = REWARD.balanceOf(address(this));
        vm.warp(1 days);
        manifestation.harvest();
        uint bal_1 = REWARD.balanceOf(address(this));
        // console.log('bal0: %s', fromWei(bal_0));
        // console.log('bal1: %s', fromWei(bal_1));
        uint dailyHarvest = fromWei(bal_1 - bal_0);
        // console.log('dailyHarvest: %s', fromWei(dailyHarvest));
        assertEq(dailyHarvest, rewardPerDay);
        console.log("[+] harvested accurate amount.");

    }

    // [userInfo]
    function testUserInfo() public {
        uint _depositAmount = toWei(100);
        uint _withdrawAmount = toWei(50);
        uint _amount = _depositAmount - _withdrawAmount;

        uint _depositTime = 1 days;
        uint _withdrawTime = 3 days;

        uint _timeDelta = 2 days;
        uint _deltaDays = 2;

        // moves (warps): to Day One.
        vm.warp(_depositTime);
        // deposits 100 tokens.
        _deposit(_depositAmount);

        // moves (warps): to Day Three.
        vm.warp(_withdrawTime);
        // withdraws: half the deposited amount.
        _withdraw(_withdrawAmount);

        // moves (warps): to Day Three.
        vm.warp(3 days);
        
        uint accRewardPerShare = manifestation.accRewardPerShare();
        uint _rewardDebt = _amount * accRewardPerShare / 1e12;

        (uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) = _userInfo(address(this));

        // console.log('deposited: %s', fromWei(amount));
        // console.log('rewardDebt: %s', rewardDebt);
        // console.log('_rewardDebt: %s', _rewardDebt);
        // console.log('withdrawTime: %s', withdrawTime);
        // console.log('depositTime: %s', depositTime);
        // console.log('timeDelta: %s', timeDelta);
        // console.log('deltaDays: %s', deltaDays);

        assertEq(amount, _amount);
        console.log('[+] (deposited) amount reported accurately.');

        assertEq(rewardDebt, _rewardDebt);
        console.log('[+] rewardDebt reported accurately.');

        assertEq(withdrawTime, _withdrawTime);
        console.log('[+] withdrawTime reported accurately.');

        assertEq(depositTime, _depositTime);
        console.log('[+] depositTime reported accurately.');

        assertEq(timeDelta, _timeDelta);
        console.log('[+] timeDelta reported accurately.');

        assertEq(deltaDays, _deltaDays);
        console.log('[+] deltaDays reported accurately.');
    }

    function testReclaimRewards() public {
        uint startBalance = REWARD.balanceOf(MANIFESTATION_0_ADDRESS);

        vm.startPrank(SOUL_DAO_ADDRESS);
        manifestation.setReclaimable(true);
        vm.stopPrank();

        vm.startPrank(SOUL_DAO_ADDRESS);
        // proves: reverts when soulDAO tries to reclaim rewards.
        vm.expectRevert();
        manifestation.reclaimRewards();
        vm.stopPrank();

        vm.startPrank(DAO_ADDRESS);
        manifestation.toggleActive(false);
        // reclaims: when active, inactive emergency, and isReclaimable.
        manifestation.reclaimRewards();
        uint endBalance = REWARD.balanceOf(MANIFESTATION_0_ADDRESS);
        vm.stopPrank();

        // console.log('start balance: %s', startBalance);
        // console.log('end balance: %s', endBalance);

        assertTrue(startBalance > endBalance);
        console.log('[+] reclaimed rewards successfully.');

    }

    function testEmergencyWithdraw() public {

    }

}
