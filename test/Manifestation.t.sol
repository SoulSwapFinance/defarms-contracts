// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";
import { Utilities } from "./utils/Utilities.sol";

import "src/Manifestation.sol";
import "src/Manifester.sol";

contract TestContract is Test {
    Manifester manifester;
    Manifestation manifestation;
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
    address nativeOracle = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;
    address rewardAddress = 0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07; // SOUL
    address depositAddress = 0xa2527Af9DABf3E3B4979d7E0493b5e2C6e63dC57; // SOUL-FTM
    address assetAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM
    address wnativeAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM

    // sets: Key Components
    function setUp() public virtual {
        setAccounts();
        deployManifester();
    }

    // sets: Accounts
    function setAccounts() public virtual {
        utils = new Utilities();
        admins = utils.createUsers(5);
        users = utils.createUsers(5);

        // creates: administrators //
        soulDAO = admins[0];
        vm.label(soulDAO, "SoulSwap DAO");
        DAO = admins[0];
        vm.label(DAO, "Project DAO");

        // creates: users //
        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
    }

    // deploys: Manifester Contract
    function deployManifester() public virtual {
        manifester = new Manifester(
            wnativeAddress,
            nativeOracle,
            oracleDecimals,
            nativeSymbol
        );
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

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }
}
