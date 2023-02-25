// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";
import { Utilities } from "../utils/Utilities.sol";

import "src/Manifestation.sol";
import "src/Manifester.sol";
import "src/mocks/MockToken.sol";
import "src/mocks/MockPair.sol";
import "src/mocks/MockFactory.sol";

contract c is Test {
    Manifester manifester;
    Manifestation manifestation;
    MockToken rewardToken;
    MockToken wnativeToken;
    MockToken usdcToken;
    MockToken depositToken;
    MockPair nativePair;
    MockPair stablePair;

    MockFactory public factory;
    Utilities internal utils;

    // constants //
    uint public oracleDecimals = 8;
    uint public duraDays = 90;
    uint public feeDays = 14;
    uint public dailyReward = 100;
    uint public initialSupply = 1_000_000_000;

    // admins //
    address payable[] internal admins;
    address internal soulDAO; // = msg.sender;
    address internal daoAddress = msg.sender;

    // addresses //
    address nativeOracle = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc; // FTM [250]

}