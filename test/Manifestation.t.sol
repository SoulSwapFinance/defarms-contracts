// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";
import { Utilities } from "./utils/Utilities.sol";

import "src/Manifestation.sol";
import "src/Manifester.sol";
import "src/mocks/MockToken.sol";
import "src/mocks/MockFactory.sol";

contract ManifestationTest is Test {
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
    address assetAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM
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

    // deploys: Deposit Token (todo: create with factory)
    // function createDepositToken() public virtual {
    //     depositToken = new SoulSwapPair(
    //         "DepositToken",
    //         "DEPOSIT",
    //         1_000_000_000
    //     );
    //     console.log("[SUCCESS] DepositToken Deployed");
    // }

    // creates: New Manifestation
    function createManifestation() public {
        deployManifester();
        deployRewardToken();
        deployDepositToken();
        // createDepositPair();
        // address rewardAddress = address(rewardToken);
        // address depositAddress = address(depositToken);

        manifester.createManifestation(
        address(rewardToken),       // address rewardAddress, 
        address(depositToken)       // address depositAddress,
        // daoAddress               // address daoAddress,
        // duraDays,                // uint duraDays, 
        // feeDays,                 // uint feeDays, 
        // dailyReward              // uint dailyReward
        );
        console.log("[SUCCESS] Manifestation Created");
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

    // tests: StartTime
    function testStartTime() public virtual {
        createManifestation();
        initializeManifestation(0);

        Manifestation _manifestation = Manifestation(manifester.manifestations(0));
        uint startTime = _manifestation.startTime();
        console.log("start time: %s", startTime);
    }

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }
}
