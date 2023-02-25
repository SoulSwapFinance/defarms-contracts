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
    // ISoulSwapPair depositToken;
    MockFactory factory;
    Utilities internal utils;

    // constants //
    uint public oracleDecimals = 8;
    uint public duraDays = 90;
    uint public feeDays = 14;
    uint public dailyReward = 100;
    string public nativeSymbol = "FTM";

    // admins //
    address payable[] internal admins;
    address internal soulDAO; // = msg.sender;
    // address internal daoAddress; // = msg.sender;

    // users //
    address payable[] internal users;
    address internal alice;
    address internal bob;

    // addresses //
    address nativeOracle = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;
    // address rewardAddress = 0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07; // SOUL
    // address depositAddress = 0xa2527Af9DABf3E3B4979d7E0493b5e2C6e63dC57; // SOUL-FTM
    // address assetAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM
    address wnativeAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM


    // deploys: Contracts
    function deployContracts() public virtual {
        deployManifester();
        deployFactory();
        deployRewardToken();
        deployDepositToken();
    }

    // deploys: Manifester Contract
    function deployManifester() public virtual {
        manifester = new Manifester(
            wnativeAddress,
            nativeOracle,
            oracleDecimals,
            nativeSymbol
        );

        console.log('[SUCCESS] Manifester Deployed');
    }

    // deploys: Mock Factory
    function deployFactory() public virtual {
        factory = new MockFactory();
        console.log("[SUCCESS] SoulSwapFactory Deployed");
    }

    // deploys: Reward Token
    function deployRewardToken() public virtual {
        rewardToken = new MockToken(
            "RewardToken",
            "REWARD",
            1_000_000_000
        );
        console.log("[SUCCESS] RewardToken Deployed");
    }

    // deploys: Deposit Token (todo: create with factory)
    function deployDepositToken() public virtual {
        depositToken = new MockToken(
            "DepositToken",
            "DEPOSIT",
            1_000_000_000
        );
        console.log("[SUCCESS] DepositToken Deployed");
    }


    // tests: Sacrifice Accuracy
    function testSacrifice() public {
        deployManifester();
        uint totalRewards = 100_000;
        uint expected = 1_000;
        uint actual = manifester.getSacrifice(totalRewards) / 1E18;
        console.log('expected: %s, actuals: %s', expected, actual);
        assertEq(actual, expected, "ok");
    }

    // creates: New Manifestation
    function createManifestation() public {
        deployContracts();

        manifester.createManifestation(
        address(rewardToken),       // address rewardAddress, 
        address(depositToken)       // address depositAddress,
        // daoAddress               // address daoAddress,
        // duraDays,                // uint duraDays, 
        // feeDays,                 // uint feeDays, 
        // dailyReward              // uint dailyReward
        );
    }

    // tests: Manifestation Initialization
    function initializeManifestation(uint id) public virtual {
        createManifestation();
        address daoAddress = manifester.daos(id);
        address rewardAddress = manifester.rewards(id);
        console.log('daoAddress: %s', daoAddress);
        console.log('rewardAddress: %s', rewardAddress);
        manifester.initializeManifestation(
            0                 // uint id,
            // rewardAddress,
            // depositAddress
            // _daoAddress,
            // _mAddress
        );
        console.log('[SUCCESS] Manifestation Initialized');
    }

    // tests: Manifestation Creation
    function testManifestation() public virtual {
        createManifestation();
        address actual = manifester.manifestations(0);
        console.log("Manifestation [0] Address: %s", actual);
        // expect the address to not be the zero address //
        assertEq(actual != address(0), true, "ok");
    }

    // tests: Manifestation Initialization
    function testInitialization() public virtual {
        initializeManifestation(0);
    }


    // tests: Manifestation Launch
    // function testLaunch() public {
    //     createManifestation();
        // uint id = 0;
        // uint manifestation;
        // manifester.launchManifestation(
        //     id,
        //     duraDays,
        //     dailyReward,
        //     feeDays
        // );
        // address actual = manifester.manifestations(0);
        // console.log("Manifestation [0] Address: %s", actual);
        // expect the address to not be the zero address //
        // assertEq(actual != address(0), true, "ok");
    // }

}
