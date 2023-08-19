// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../src/forge/Script.sol";
import "../src/Manifester.sol";

contract ManifesterScript is Script {

    address public _factoryAddress = 0x5BB2a9984de4a69c05c996F7EF09597Ac8c9D63a;    // avax
    address public _auraAddress = 0x268D3D63088821C17c59860D6B9476680a4843d2;       // avax
    address public _usdcAddress = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;       // avax
    address public _wnativeAddress = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;    // avax
    address public _enchantressAddress = 0xFd63Bf84471Bc55DD9A83fdFA293CCBD27e1F4C8;

    // uint public _oracleDecimals = 8;
    string public _nativeSymbol = 'NATIVE';

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        Manifester manifester = new Manifester(
            _factoryAddress,
            _auraAddress,
            _usdcAddress,
            _wnativeAddress,
            // _nativeOracle, 
            _enchantressAddress,
            // _oracleDecimals,
            _nativeSymbol
        );

        // silences warning.
        manifester;

        vm.stopBroadcast();
    }
}
