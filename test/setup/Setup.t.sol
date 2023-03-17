// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "src/Manifestation.sol";
import "src/Manifester.sol";
import "src/mocks/MockToken.sol";
// import "src/mocks/MockPair.sol";
import "src/mocks/MockFactory.sol";

import { stdStorage, StdStorage, Test, Vm } from "forge-std/Test.sol";
import { Utilities } from "../utils/Utilities.sol";
import { console } from "forge-std/console.sol";

contract Setup is Test {
    // contracts.
    Manifester manifester;
    Manifestation manifestation;

    // mock custom tokens.
    MockToken AURA;
    MockToken DEPOSIT;
    MockToken REWARD;

    // mock asset tokens.
    MockToken USDC;
    MockToken WNATIVE;

    MockFactory public factory;
    Utilities internal utils;

    // addresses //
    address public MANIFESTER_ADDRESS;
    address public MANIFESTATION_0_ADDRESS;

    address public FACTORY_ADDRESS;

    address public AURA_ADDRESS;
    address public DEPOSIT_ADDRESS;
    address public REWARD_ADDRESS;

    address public USDC_ADDRESS;
    address public WNATIVE_ADDRESS;

    // numeric constants //
    // uint public immutable ORACLE_DECIMALS = 8;
    uint public immutable DURA_DAYS = 90;
    // uint public immutable DELAY_DAYS = 1;
    uint public immutable FEE_DAYS = 14;
    uint public immutable DAILY_REWARD = 100;
    uint public immutable INITIAL_SUPPLY = 1_000_000_000;
    uint public immutable ONE_DAY = 1 days;

    // admins //
    address payable[] internal admins;
    address internal SOUL_DAO_ADDRESS = address(0xea);
    address internal DAO_ADDRESS = address(0xee);
    address internal CREATOR_ADDRESS = address(this);

    // addresses //
    // address public NATIVE_ORACLE_ADDRESS = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc; // FTM [250]
    address public ENCHANTRESS_ADDRESS = 0xFd63Bf84471Bc55DD9A83fdFA293CCBD27e1F4C8;

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

        // initializes: AURA Token
        AURA = new MockToken(
            "SoulAura",
            "AURA",
            INITIAL_SUPPLY                     // totalSupply
        );
        AURA_ADDRESS = address(AURA);

        // initializes: Reward Token
        REWARD = new MockToken(
            "RewardToken",
            "REWARD",
            INITIAL_SUPPLY                     // totalSupply
        );
        REWARD_ADDRESS = address(REWARD);

        // initializes: Reward Token
        DEPOSIT = new MockToken(
            "DepositToken",
            "DEPOSIT",
            INITIAL_SUPPLY                     // totalSupply
        );
        DEPOSIT_ADDRESS = address(DEPOSIT);

        // deploys: Manifester Contract
        manifester = new Manifester(
            FACTORY_ADDRESS,
            AURA_ADDRESS,
            USDC_ADDRESS,
            WNATIVE_ADDRESS,
            // NATIVE_ORACLE_ADDRESS,
            ENCHANTRESS_ADDRESS,
            // ORACLE_DECIMALS,
            WNATIVE.symbol()
        );
        MANIFESTER_ADDRESS = address(manifester);

        // uint totalRewards = manifester.getTotalRewards(DURA_DAYS, DAILY_REWARD);
        // uint sacrifice = manifester.getSacrifice(fromWei(totalRewards));
        // (uint toDAO, uint toEnchanter) = manifester.getSplit(sacrifice);
        // console.log('total rewards: %s', fromWei(totalRewards));
        // console.log('sacrifice: %s', fromWei(sacrifice));
        // console.log('toDAO: %s', fromWei(toDAO));
        // console.log('toEnchanter: %s', fromWei(toEnchanter));

        // address manifestationAddress = manifester.generateManifestation(DEPOSIT_ADDRESS, 0);
        // console.log('manifestation address: %s', manifestationAddress);

        // approves: manifestation to transferFrom REWARD token.
        REWARD.approve(MANIFESTER_ADDRESS, toWei(INITIAL_SUPPLY));
        // console.log('manifesting...');

        // creates: Manifestation[0]
        manifester.createManifestationOverride(
            DEPOSIT_ADDRESS,      // address depositAddress,
            REWARD_ADDRESS,       // uint rewardAddress,
            0,                    // address enchanterId,
            // true,              // bool isNative
            DURA_DAYS,
            FEE_DAYS,
            DAILY_REWARD,
            'https://raw.githubusercontent.com/SoulSwapFinance/assets/prod/blockchains/fantom/assets/0xc7183455a4C133Ae270771860664b6B7ec320bB1.logo.png'
        );

        // console.log('manifestation created.');

        MANIFESTATION_0_ADDRESS = manifester.manifestations(0);
        // console.log('manifestation[0] address: %s', MANIFESTATION_0_ADDRESS);
        
        manifestation = Manifestation(MANIFESTATION_0_ADDRESS);

        // console.log('deposit address: %s', DEPOSIT_ADDRESS);
        // console.log('this address: %s', address(this));
        // console.log('soulDAO address: %s', manifester.soulDAO());
        // console.log('manifestation[0] address created: %s', address(manifestation));
        // console.log('soulDAO [M0] address: %s', manifestation.soulDAO());
        // console.log('updating deposit address...');
        // manifestation.setDepositAddress(DEPOSIT_ADDRESS);
        // console.log('updated deposit address');
        // console.log('updating deposit address...');
        // manifester.updateDepositAddress(0, DEPOSIT_ADDRESS);
        // console.log('updated deposit address: %s', DEPOSIT_ADDRESS);

        // manifestation = Manifestation(MANIFESTATION_0_ADDRESS);
        // console.log('manifestation: %s', manifestation);
        
        // sets: start time, end time
        // console.log('setting delay...');
        // id, delayDays
        vm.startPrank(SOUL_DAO_ADDRESS);
        vm.expectRevert();
        manifester.setDelay(0, 0);
        vm.stopPrank();
        // console.log('[+] delay reverts when non-DAO sets delay.');

        manifester.setDelay(0, 0);
        // console.log('[+] delay set successfully.');

        // unpauses: Manifestation[0].
        // console.log('toggling active...');
        // console.log('dao [m0] %s', manifestation.DAO());
        manifestation.toggleActiveOverride(true);
        // console.log('[+] active set successfully.');

        // approves: deposit token to Manifestation[0].
        // console.log('approving deposit...');
        DEPOSIT.approve(MANIFESTATION_0_ADDRESS, toWei(INITIAL_SUPPLY));
        // console.log('deposit approved');

        // for demonstration purposes (on `totalDeposits`).
        DEPOSIT.transfer(MANIFESTATION_0_ADDRESS, toWei(100));

        // sets: feeRate to 14%.
        // console.log('setting fee days...');
        // manifestation.setFeeDaysOverride(14);
        // console.log('fee days set');

        // sets: addresses for test clarity.
        manifester.setSoulDAO(SOUL_DAO_ADDRESS);
        manifestation.setDAO(DAO_ADDRESS);
        vm.prank(DAO_ADDRESS);
        manifestation.acceptDAO();
        vm.stopPrank();


    }

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}