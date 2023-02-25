// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./setup/c.t.sol";

contract ManifesterTest is Test, c {

    function deployContracts() public virtual {

        // deploys: Mock Factory
        c.factory = new MockFactory();

        // deploys: Native Token
        c.wnativeToken = new MockToken(
            "Wrapped Fantom",
            "WFTM",
            c.initialSupply                     // totalSupply
        );

        // deploys: USDC Token
        c.usdcToken = new MockToken(
            "USD Coin",
            "USDC",
            c.initialSupply                     // totalSupply
        );

        // deploys: Reward Token
        c.rewardToken = new MockToken(
            "RewardToken",
            "REWARD",
            c.initialSupply                     // totalSupply
        );

        // deploys: Deposit Token
        c.depositToken = new MockToken(
            "DepositToken",
            "DEPOSIT",
            c.initialSupply                     // totalSupply
        );

        c.nativePair = new MockPair(
            address(c.factory),                 // factoryAddress
            address(c.rewardToken),             // token0Address
            address(c.wnativeToken),            // token1Address
            address(c.wnativeToken),            // wnativeAddress
            c.initialSupply                     // totalSupply
        );

        c.stablePair = new MockPair(
            address(c.factory),                 // factoryAddress
            address(c.rewardToken),             // token0Address
            address(c.usdcToken),               // token1Address
            address(c.wnativeToken),            // wnativeAddress
            c.initialSupply                     // totalSupply
        );

        // deploys: Manifester Contract
        c.manifester = new Manifester(
            address(c.factory),
            address(c.usdcToken),
            address(c.wnativeToken),
            c.nativeOracle,
            c.oracleDecimals,
            c.wnativeToken.symbol()
        );
    }

    // creates: New Manifestation
    function createManifestation() public {
        deployContracts();

        c.manifester.createManifestation(
            address(c.rewardToken),       // address rewardAddress, 
            address(c.depositToken),      // address depositAddress,
            c.daoAddress,                 // address daoAddress,
            c.duraDays,                   // uint duraDays, 
            c.feeDays,                    // uint feeDays, 
            c.dailyReward                 // uint dailyReward
        );
    }

    /*/ CONTRACT TESTS /*/
    // 1 // Create Manifestation
    // 2 // Initialize Manifestation
    // 3 // Native Pair
    // 4 // Stable Pair
    // 5 // Calculate Sacrifice

    // [1]: Manifestation Creation
    function testCreation() public virtual {
        createManifestation();
        address mAddress = c.manifester.manifestations(0);
        bool expected = true;
        bool actual = mAddress != address(0);
        // expect the address to not be the zero address //
        assertEq(actual, expected, "ok");
        console.log("[+] mAddress: %s", mAddress);
    }

    // [2]: Manifestation Initialization
    function testInitialization() public virtual {
        uint id = 0;
        createManifestation();
        c.manifester.initializeManifestation(id);

        address mAddress = c.manifester.manifestations(id);
        address rewardAddress = address(c.rewardToken);
        address depositAddress = address(c.depositToken);

        (address _mAddress, , , , , ,)         = c.manifester.mInfo(id);
        (,address _rewardAddress, , , , ,)     = c.manifester.mInfo(id);
        (, ,address _depositAddress, , , ,)    = c.manifester.mInfo(id);
        (, , ,address _daoAddress, , ,)        = c.manifester.mInfo(id);
        (, , , ,uint _duraDays, ,)             = c.manifester.mInfo(id);
        (, , , , ,uint _feeDays,)              = c.manifester.mInfo(id);
        (, , , , , ,uint _dailyReward)         = c.manifester.mInfo(id);

        // verifies: mAddress
        assertEq(_mAddress, mAddress, "ok");
        console.log("[+] mAddress: %s", mAddress);

        // verifies: rewardAddress
        assertEq(_rewardAddress, rewardAddress, "ok");
        console.log("[+] rewardAddress: %s", rewardAddress);

        // verifies: depositAddress
        assertEq(_depositAddress, depositAddress, "ok");
        console.log("[+] depositAddress: %s", depositAddress);

        // verifies: daoAddress
        assertEq(_daoAddress, c.daoAddress, "ok");
        console.log("[+] daoAddress: %s", c.daoAddress);
        // console.log("[+] thisAddress: %s", address(this));
        // console.log("[+] myAddress: %s", msg.sender);

        // verifies: duraDays
        assertEq(_duraDays, c.duraDays, "ok");
        console.log("[+] duraDays: %s", c.duraDays);

        // verifies: feeDays
        assertEq(_feeDays, c.feeDays, "ok");
        console.log("[+] feeDays: %s", c.feeDays);

        // verifies: dailyReward
        assertEq(_dailyReward, c.dailyReward, "ok");
        console.log("[+] dailyReward: %s", c.dailyReward);

    }

    // [3] test: Native Pair
    function testPairs() public {
        deployContracts();
        // bool isNative = true;
        // bool _isNative = c.nativePair.isNative();

        bool _isNative_Native = c.nativePair.isNative();
        bool _isNative_Stable = c.stablePair.isNative();
        
        bool isNative_Native = true;
        bool isNative_Stable = false;

        assertEq(_isNative_Native, isNative_Native, "ok");
        assertEq(_isNative_Stable, isNative_Stable, "ok");

        console.log("[+] isNative(nativePair): %s", c.nativePair.isNative());
        console.log("[+] isNative(stablePair): %s", c.stablePair.isNative());

        console.log("[+] nativePair: %s", address(c.nativePair));
        console.log("[+] stablePair: %s", address(c.stablePair));
    }

    // tests: Sacrifice Accuracy
    function testSacrifice() public {
        deployContracts();
        uint totalRewards = 100_000;
        uint expected = 1_000;
        uint actual = c.manifester.getSacrifice(totalRewards) / 1E18;
        // console.log('expected: %s, actuals: %s', expected, actual);
        assertEq(actual, expected, "ok");
        console.log("[+] getSacrifice(100K): %s", actual);
    }

}
