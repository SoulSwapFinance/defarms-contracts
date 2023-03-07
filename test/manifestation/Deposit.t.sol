// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../setup/Setup.t.sol";

contract DepositTest is Test, Setup {
    
    function _deposit(uint _amount) internal {
        manifestation.deposit(_amount);
    }

    function testDeposit() public {
        uint _amount = toWei(100);
        _deposit(_amount);
    }

}
