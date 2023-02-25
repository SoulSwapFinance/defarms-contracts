// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";
import { Utilities } from "./utils/Utilities.sol";

import "src/Manifestation.sol";
import "src/Manifester.sol";
import "src/mocks/MockToken.sol";
import "src/mocks/MockFactory.sol";

contract ManifesterTest is Test {
    Manifester manifester;
    Manifestation manifestation;
    MockToken rewardToken;
    MockToken depositToken;
    MockToken wnativeToken;
    MockToken usdcToken;
    // ISoulSwapPair depositToken;
    MockFactory factory;
    Utilities internal utils;

    // constants //
    uint public oracleDecimals = 8;
    uint public duraDays = 90;
    uint public feeDays = 14;
    uint public dailyReward = 100;
    // string public nativeSymbol = "FTM";

    // admins //
    address payable[] internal admins;
    address internal soulDAO; // = msg.sender;
    address internal daoAddress = msg.sender;

    // users //
    address payable[] internal users;
    address internal alice;
    address internal bob;

    // addresses //
    address nativeOracle = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc; // FTM Oracle (250)
    // address rewardAddress = 0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07; // SOUL
    // address depositAddress = 0xa2527Af9DABf3E3B4979d7E0493b5e2C6e63dC57; // SOUL-FTM
    // address assetAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM
    // address wnativeAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM

    function deployContracts() public virtual {
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

        // deploys: Mock Factory
        factory = new MockFactory();

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
    // 3 // Calculate Sacrifice

    // tests: Manifestation Creation
    function testCreation() public virtual {
        createManifestation();
        address mAddress = manifester.manifestations(0);
        bool actual = mAddress != address(0);
        bool expected = true;
        // expect the address to not be the zero address //
        assertEq(actual, expected, "ok");
        console.log("[PASS]: mAddress: %s", mAddress);
    }

    // tests: Manifestation Initialization
    function testInitialization() public virtual {
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
        assertEq(mAddress, _mAddress, "ok");
        console.log("[PASS]: mAddress: %s", _mAddress);

        // verifies: rewardAddress
        assertEq(rewardAddress, _rewardAddress, "ok");
        console.log("[PASS]: rewardAddress: %s", rewardAddress);

        // verifies: depositAddress
        assertEq(depositAddress, _depositAddress, "ok");
        console.log("[PASS]: depositAddress: %s", depositAddress);

        // verifies: daoAddress
        assertEq(daoAddress, _daoAddress, "ok");
        console.log("[PASS]: daoAddress: %s", daoAddress);

        // verifies: duraDays
        assertEq(duraDays, _duraDays, "ok");
        console.log("[PASS]: duraDays: %s", duraDays);

        // verifies: feeDays
        assertEq(feeDays, _feeDays, "ok");
        console.log("[PASS]: feeDays: %s", feeDays);

        // verifies: dailyReward
        assertEq(dailyReward, _dailyReward, "ok");
        console.log("[PASS]: dailyReward: %s", dailyReward);

    }

    // tests: Sacrifice Accuracy
    function testSacrifice() public {
        deployContracts();
        uint totalRewards = 100_000;
        uint expected = 1_000;
        uint actual = manifester.getSacrifice(totalRewards) / 1E18;
        // console.log('expected: %s, actuals: %s', expected, actual);
        assertEq(actual, expected, "ok");
        console.log("[PASS]: getSacrifice(100K): %s", actual);
    }

}
