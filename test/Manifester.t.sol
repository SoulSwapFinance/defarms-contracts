// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";
import { Utilities } from "./utils/Utilities.sol";

import "src/Manifester.sol";

contract TestContract is Test {
    Manifester manifester;
    Utilities internal utils;

    // constants //
    uint public oracleDecimals = 8;
    uint public duraDays = 90;
    uint public feeDays = 14;
    uint public dailyReward = 100;
    string public nativeSymbol = "FTM";

    // admins //
    address payable[] internal admins;
    address internal soulDAO;
    address internal DAO;

    // users //
    address payable[] internal users;
    address internal alice;
    address internal bob;

    // addresses //
    address nativeOracle = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc; // NATIVE ORACLE
    address rewardAddress = 0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07; // SOUL
    address depositAddress = 0xa2527Af9DABf3E3B4979d7E0493b5e2C6e63dC57; // SOUL-FTM
    address assetAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM
    address wnativeAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM

    // deploys: Manifester Contract
    function deployManifester() public virtual {
        manifester = new Manifester(
            wnativeAddress,
            nativeOracle,
            oracleDecimals,
            nativeSymbol
        );
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
        deployManifester();

        manifester.createManifestation(
        rewardAddress,      // address rewardAddress, 
        depositAddress,     // address depositAddress,
        duraDays,           // uint duraDays, 
        feeDays,            // uint feeDays, 
        dailyReward         // uint dailyReward
        );
    }

    // tests: Manifestation Creation
    function testManifestation() public {
        createManifestation();
        address actual = manifester.manifestations(0);
        console.log("Manifestation [0] Address: %s", actual);
        // expect the address to not be the zero address //
        assertEq(actual != address(0), true, "ok");
    }

}
