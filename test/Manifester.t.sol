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

    function testSacrifice() public {
        deployManifester();
        uint totalRewards = 100_000;
        uint expectation = 1_000;
        uint result = manifester.getSacrifice(totalRewards) / 1E18;
        console.log('expectation: %s, results: %s', expectation, result);
        assertEq(expectation, result, "ok");
    }

}
