// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "src/Tokens.sol";

contract MockPair is ERC20 {

    address public token0;
    address public token1;
    address public factory;
    address private wnativeAddress;

    bool public isNative;

    constructor(
        address _factory,
        address _token0,
        address _token1,

        address _wnativeAddress,
        uint _supply
    ) ERC20("SoulSwap LP", "SOUL-LP") {
        _mint(msg.sender, _supply * 1E18);

        wnativeAddress = _wnativeAddress;

        token0 = _token0;
        token1 = _token1;
        factory = _factory;

        isNative = _token0 == _wnativeAddress || _token1 == _wnativeAddress;
    }
}
