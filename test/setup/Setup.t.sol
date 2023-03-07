// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "src/Manifestation.sol";
import "src/Manifester.sol";
import "src/mocks/MockToken.sol";
import "src/mocks/MockPair.sol";
import "src/mocks/MockFactory.sol";

import { stdStorage, StdStorage, Test, Vm } from "forge-std/Test.sol";
import { Utilities } from "../utils/Utilities.sol";
import { console } from "forge-std/console.sol";

contract Setup {
    // contracts.
    Manifester manifester;
    Manifestation manifestation;

    // mock custom tokens.
    MockToken DEPOSIT;
    MockToken REWARD;

    // mock asset tokens.
    MockToken USDC;
    MockToken WNATIVE;

    // mock pairs.
    MockPair NATIVE_PAIR;
    MockPair STABLE_PAIR;

    MockFactory public factory;
    Utilities internal utils;

    // addresses //
    address public MANIFESTER_ADDRESS;
    address public MANIFESTATION_0_ADDRESS;

    address public FACTORY_ADDRESS;
    address public REWARD_ADDRESS;
    address public DEPOSIT_ADDRESS;

    address public USDC_ADDRESS;
    address public WNATIVE_ADDRESS;

    address public NATIVE_PAIR_ADDRESS;
    address public STABLE_PAIR_ADDRESS;

    // numeric constants //
    uint public immutable ORACLE_DECIMALS = 8;
    uint public immutable DURA_DAYS = 90;
    uint public immutable FEE_DAYS = 14;
    uint public immutable DAILY_REWARD = 100;
    uint public immutable INITIAL_SUPPLY = 1_000_000_000 * 1E18;
    uint public immutable ONE_DAY = 1 days;

    // admins //
    address payable[] internal admins;
    address internal SOUL_DAO_ADDRESS; // = msg.sender;
    address internal DAO_ADDRESS = msg.sender;
    address internal CREATOR_ADDRESS = address(this); // 0xFd63Bf84471Bc55DD9A83fdFA293CCBD27e1F4C8

    // addresses //
    address NATIVE_ORACLE_ADDRESS = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc; // FTM [250]

    // initializes tokens, pairs
    constructor() {

        // initializes: Mock Factory
        factory = new MockFactory();
        FACTORY_ADDRESS = address(factory);

        // initializes: Native Token
        WNATIVE = new MockToken(
            "Wrapped Fantom",
            "WFTM",
            INITIAL_SUPPLY                     // totalSupply
        );
        WNATIVE_ADDRESS = address(WNATIVE);

        // initializes: USDC Token
        USDC = new MockToken(
            "USD Coin",
            "USDC",
            INITIAL_SUPPLY                     // totalSupply
        );
        USDC_ADDRESS = address(USDC);

        // initializes: Reward Token
        REWARD = new MockToken(
            "RewardToken",
            "REWARD",
            INITIAL_SUPPLY                     // totalSupply
        );
        REWARD_ADDRESS = address(REWARD);

        NATIVE_PAIR = new MockPair(
            FACTORY_ADDRESS,                  // factoryAddress
            address(REWARD),             // token0Address
            address(WNATIVE),            // token1Address
            address(WNATIVE),            // wnativeAddress
            INITIAL_SUPPLY                    // totalSupply
        );
        NATIVE_PAIR_ADDRESS = address(NATIVE_PAIR);
        DEPOSIT_ADDRESS = address(NATIVE_PAIR); 

        STABLE_PAIR = new MockPair(
            FACTORY_ADDRESS,                  // factoryAddress
            address(REWARD),             // token0Address
            address(USDC),               // token1Address
            address(WNATIVE),            // wnativeAddress
            INITIAL_SUPPLY                    // totalSupply
        );
        STABLE_PAIR_ADDRESS = address(STABLE_PAIR);

        // deploys: Manifester Contract
        manifester = new Manifester(
            FACTORY_ADDRESS,
            USDC_ADDRESS,
            WNATIVE_ADDRESS,
            NATIVE_ORACLE_ADDRESS,
            ORACLE_DECIMALS,
            WNATIVE.symbol()
        );
        MANIFESTER_ADDRESS = address(manifester);

        // creates: Manifestation[0]
        manifester.createManifestation(
            DEPOSIT_ADDRESS,      // address depositAddress,
            REWARD_ADDRESS,       // address rewardAddress, 
            0,                    // address rewardAddress, 
            true                  // bool isNative
        );

        MANIFESTATION_0_ADDRESS = manifester.manifestations(0);
        manifestation = Manifestation(MANIFESTATION_0_ADDRESS);

        // approves: manifestation to transferFrom REWARD token.
        REWARD.approve(MANIFESTER_ADDRESS, INITIAL_SUPPLY * 1E18);

        // initializes: Manifestation[0]
        manifester.initializeManifestation(0);
        
        // sets Manifestation[0]: rewards and duration variables.
        manifester.launchManifestation(
            0,            // id
            DURA_DAYS,    // duraDays
            DAILY_REWARD, // dailyRewards
            FEE_DAYS      // feeDays
        );
        
        // sets: start time, end time
        manifestation.setDelay(0);

        // unpauses: Manifestation[0].
        manifestation.toggleActive(true);

        // approves: deposit token to Manifestation[0].
        ERC20(DEPOSIT_ADDRESS).approve(MANIFESTATION_0_ADDRESS, INITIAL_SUPPLY * 1E18);
    }

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}