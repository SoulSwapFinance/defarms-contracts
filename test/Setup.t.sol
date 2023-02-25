// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";
import { Utilities } from "./utils/Utilities.sol";

import "src/Manifestation.sol";
import "src/Manifester.sol";

contract SetupContract is Test {
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
    address internal soulDAO; // = msg.sender;
    address internal daoAddress; // = msg.sender;

    // users //
    address payable[] internal users;
    address internal alice;
    address internal bob;

    // sets: Accounts
    function setAccounts() public virtual {
        utils = new Utilities();
        admins = utils.createUsers(5);
        users = utils.createUsers(5);

        // creates: administrators //
        soulDAO = admins[0];
        vm.label(soulDAO, "SoulSwap DAO");
        daoAddress = admins[1];
        vm.label(daoAddress, "Project DAO");

        // creates: users //
        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
    }
}
