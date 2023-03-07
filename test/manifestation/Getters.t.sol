// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;
import "../setup/Setup.t.sol";

contract GettersTest is Test, Setup {

    // function _getTVL() internal view returns (uint _TVL) {
    //     _TVL = manifestation.getTVL();
    // }

    // function _getPricePerToken() internal view returns (uint _price) {
    //     _price = manifestation.getPricePerToken();
    // }

    // [multiplier] tests: TVL accuracy.
    function testGetMultiplier() public {
        (uint _from, uint _to) = (100, 400);
        // uint TO = 400;
        uint _multiplier = _to - _from;
        uint multiplier = manifestation.getMultiplier(_from, _to);
        // console.log('multiplier: %s', multiplier);
        assertEq(multiplier, _multiplier);
    }

    // [TVL] tests: TVL accuracy.
    function testGetTVL() public {}

    // [price] tests: pricePerToken accuracy.
    function testGetPricePerToken() public {}

    // [fee] tests: feeRate accuracy.
    function testGetFeeRate() public {
        uint deltaDays = 10;
        uint _feeRate = (FEE_DAYS - deltaDays) * 1E18;

        uint feeRate = manifestation.getFeeRate(deltaDays);
        // console.log('feeRate: %s', feeRate);
        // console.log('_feeRate: %s', _feeRate);
        assertEq(feeRate, _feeRate);
        console.log('[+] feeRate reported accurately.');
    }

    // [bonus] tests: bonus shares.
    function testGetBonusAmount() public {
        address _account = address(this);
        uint _amount = toWei(500);
        uint _boost = toWei(10);
        // expectation: bonus = boost(10%) of amount(500) = 50.
        uint _bonus = toWei(50);

        uint boost = manifestation.boost();
        uint bonus = manifestation.getBonusAmount(_account, _amount);
        // console.log('deposited: %s', fromWei(_amount));
        // console.log('boost: %s%', fromWei(boost));
        // console.log('bonus: %s', fromWei(bonus));
        assertEq(boost, _boost);
        assertEq(bonus, _bonus);
        console.log('[+] bonus amount reported accurately.');
    }
}