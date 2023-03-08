// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import 'src/lib/Libraries.sol';

contract MockToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply * 1E18);
    }
}