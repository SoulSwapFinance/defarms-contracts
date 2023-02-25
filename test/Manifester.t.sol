// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";
import { Utilities } from "./utils/Utilities.sol";

import "src/Manifestation.sol";
import "src/Manifester.sol";
import "src/mocks/MockToken.sol";
import "src/mocks/MockPair.sol";
import "src/mocks/MockFactory.sol";

contract ManifesterTest is Test {
    Manifester manifester;
    Manifestation manifestation;
    MockToken rewardToken;
    MockToken wnativeToken;
    MockToken usdcToken;
    MockToken depositToken;
    MockPair nativePair;
    MockPair stablePair;

    // ISoulSwapPair depositToken;
    // address depositAddress;
    MockFactory factory;
    Utilities internal utils;

    // constants //
    uint public oracleDecimals = 8;
    uint public duraDays = 90;
    uint public feeDays = 14;
    uint public dailyReward = 100;

    // admins //
    address payable[] internal admins;
    address internal soulDAO; // = msg.sender;
    address internal daoAddress = msg.sender;

    // addresses //
    address nativeOracle = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc; // FTM [250]

    function deployContracts() public virtual {

        // deploys: Mock Factory
        factory = new MockFactory();

        // deploys: Native Token
        wnativeToken = new MockToken(
            "Wrapped Fantom",
            "WFTM",
            1_000_000_000
        );

        // deploys: USDC Token
        usdcToken = new MockToken(
            "USD Coin",
            "USDC",
            1_000_000_000
        );

        // deploys: Reward Token
        rewardToken = new MockToken(
            "RewardToken",
            "REWARD",
            1_000_000_000
        );

        // deploys: Deposit Token
        depositToken = new MockToken(
            "DepositToken",
            "DEPOSIT",
            1_000_000_000
        );

        nativePair = new MockPair(
            address(factory),       // factoryAddress
            address(rewardToken),   // token0Address
            address(wnativeToken),  // token1Address
            address(wnativeToken),  // wnativeAddress
            1_000_000_000           // totalSupply
        );

        stablePair = new MockPair(
            address(factory),       // factoryAddress
            address(rewardToken),   // token0Address
            address(usdcToken),     // token1Address
            address(wnativeToken),  // wnativeAddress
            1_000_000_000           // totalSupply
        );

        // deploys: Manifester Contract
        manifester = new Manifester(
            address(factory),
            address(usdcToken),
            address(wnativeToken),
            nativeOracle,
            oracleDecimals,
            wnativeToken.symbol()
        );
    }

    // creates: New Manifestation
    function createManifestation() public {
        deployContracts();

        manifester.createManifestation(
            address(rewardToken),       // address rewardAddress, 
            address(depositToken),      // address depositAddress,
            daoAddress,                 // address daoAddress,
            duraDays,                   // uint duraDays, 
            feeDays,                    // uint feeDays, 
            dailyReward                 // uint dailyReward
        );
    }

    /*/ CONTRACT TESTS /*/
    // 1 // Create Manifestation
    // 2 // Initialize Manifestation
    // 3 // Native Pair
    // 4 // Stable Pair
    // 5 // Calculate Sacrifice

    // tests: Manifestation Creation
    function test_1_Creation() public virtual {
        createManifestation();
        address mAddress = manifester.manifestations(0);
        bool expected = true;
        bool actual = mAddress != address(0);
        // expect the address to not be the zero address //
        assertEq(actual, expected, "ok");
        console.log("[+] mAddress: %s", mAddress);
    }

    // tests: Manifestation Initialization
    function test_2_Initialization() public virtual {
        uint id = 0;
        createManifestation();
        manifester.initializeManifestation(id);

        address mAddress = manifester.manifestations(id);
        address rewardAddress = address(rewardToken);
        address depositAddress = address(depositToken);

        (address _mAddress, , , , , ,)         = manifester.mInfo(id);
        (,address _rewardAddress, , , , ,)     = manifester.mInfo(id);
        (, ,address _depositAddress, , , ,)    = manifester.mInfo(id);
        (, , ,address _daoAddress, , ,)        = manifester.mInfo(id);
        (, , , ,uint _duraDays, ,)             = manifester.mInfo(id);
        (, , , , ,uint _feeDays,)              = manifester.mInfo(id);
        (, , , , , ,uint _dailyReward)         = manifester.mInfo(id);

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
        assertEq(_daoAddress, daoAddress, "ok");
        console.log("[+] daoAddress: %s", daoAddress);

        // verifies: duraDays
        assertEq(_duraDays, duraDays, "ok");
        console.log("[+] duraDays: %s", duraDays);

        // verifies: feeDays
        assertEq(_feeDays, feeDays, "ok");
        console.log("[+] feeDays: %s", feeDays);

        // verifies: dailyReward
        assertEq(_dailyReward, dailyReward, "ok");
        console.log("[+] dailyReward: %s", dailyReward);

    }

    function test_3_NativePair() public {
        deployContracts();
        bool isNative = true;
        bool _isNative = nativePair.isNative();

        // native pair tests //
        // console.log("Address: %s", address(nativePair));
        // console.log("Name: %s", nativePair.name());
        // console.log("Token0: %s", nativePair.token0());
        // console.log("Token1: %s", nativePair.token1());

        assertEq(_isNative, isNative, "ok");
        console.log("[+] isNative?: %s", nativePair.isNative());
        console.log("[+] nativePair: %s", address(nativePair));
    }

    function test_4_StablePair() public {
        deployContracts();
        bool isNative = false;
        bool _isNative = stablePair.isNative();

        // stable pair tests //
        // console.log("Address: %s", address(stablePair));
        // console.log("Name: %s", stablePair.name());
        // console.log("Token0: %s", stablePair.token0());
        // console.log("Token1: %s", stablePair.token1());

        assertEq(_isNative, isNative, "ok");
        console.log("[+] isNative?: %s", stablePair.isNative());
        console.log("[+] stablePair: %s", address(stablePair));
    }

    // tests: Sacrifice Accuracy
    function test_5_Sacrifice() public {
        deployContracts();
        uint totalRewards = 100_000;
        uint expected = 1_000;
        uint actual = manifester.getSacrifice(totalRewards) / 1E18;
        // console.log('expected: %s, actuals: %s', expected, actual);
        assertEq(actual, expected, "ok");
        console.log("[+] getSacrifice(100K): %s", actual);
    }

}
