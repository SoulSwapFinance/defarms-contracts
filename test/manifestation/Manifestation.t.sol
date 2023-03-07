// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import '../setup/Setup.t.sol';

contract ManifestationTest is Test, Setup {

    function _deposit(uint _amount) internal {
        manifestation.deposit(_amount);
    }

    function _getStrings() internal view returns (
        string memory name,
        string memory symbol,
        string memory logoURI,
        string memory assetSymbol
    ) {
        name = manifestation.name();
        symbol = manifestation.symbol();
        logoURI = manifestation.logoURI();
        assetSymbol = manifestation.assetSymbol();
    }

    function _userInfo() internal view returns (uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        (amount, rewardDebt, withdrawTime, depositTime, timeDelta, deltaDays) = manifestation.getUserInfo();
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
        string memory _name = 'Manifest: RewardToken';
        string memory _symbol = 'REWARD-NATIVE MP';
        string memory _logoURI = '';
        string memory _assetSymbol = 'NATIVE';

        (string memory name, string memory symbol, string memory logoURI, string memory assetSymbol) = _getStrings();

        assertEq(name, _name);
        assertEq(symbol, _symbol);
        assertEq(logoURI, _logoURI);
        assertEq(assetSymbol, _assetSymbol);
    }

    // [deposit]: Deposit 100 tokens.
    function testDeposit() public {
        uint _amount = toWei(100);
        _deposit(_amount);
    }

    // [userInfo]
    function testUserInfo() public {
        uint _amount = toWei(100);
        _deposit(_amount);

        // moves (warps): to timestamp 100.
        vm.warp(86_402);
        // (uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) = _userInfo();
        (uint amount, , , , ,) = _userInfo();
        assertEq(amount, _amount);
        console.log('[+] deposited amount reported accurately.');
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
}
