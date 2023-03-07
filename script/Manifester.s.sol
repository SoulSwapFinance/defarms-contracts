// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../src/forge/Script.sol";
import "../src/Manifester.sol";

contract ManifesterScript is Script {

    address public _factoryAddress = 0x1120e150dA9def6Fe930f4fEDeD18ef57c0CA7eF;
    address public _auraAddress = 0xec3F962238cC6D45aEc0f97D0f150e221Ef3C42C;
    address public _usdcAddress = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public _wnativeAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public _nativeOracle = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;
    
    uint public _oracleDecimals = 8;
    string public _nativeSymbol = 'NATIVE';

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        Manifester manifester = new Manifester(
            _factoryAddress,
            _auraAddress,
            _usdcAddress,
            _wnativeAddress,
            _nativeOracle, 
            _oracleDecimals,
            _nativeSymbol
        );

        // silences warning.
        manifester;

        vm.stopBroadcast();
    }
}
