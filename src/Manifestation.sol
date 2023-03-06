// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import './lib/Libraries.sol';
import './lib/Security.sol';

contract Manifestation is IManifestation, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public creatorAddress;
    IManifester public manifester;
    address public DAO;
    address public soulDAO;
    address public wnativeAddress;
    address public usdcAddress;
    string public nativeSymbol;

    address public assetAddress;
    address public depositAddress;
    address public rewardAddress;

    IERC20 public depositToken;
    IERC20 public assetToken;
    IERC20 public rewardToken;

    string public override name;
    string public override symbol;
    string public override logoURI;
    string public override assetSymbol;
    
    uint public duraDays;
    uint public feeDays;
    uint public dailyReward;
    uint public totalRewards;
    uint public rewardPerSecond;
    uint public accRewardPerShare;
    uint public lastRewardTime;

    uint public override startTime;
    uint public override endTime;

    bool public isNativePair;

    bool public isManifested;
    bool public isSetup;
    bool public isEmergency;
    bool public isActivated;
    bool public isSettable;

    // user info
    struct Users {
        uint amount;            // deposited amount.
        uint rewardDebt;        // reward debt (see: pendingReward).
        uint withdrawTime;      // last withdrawal time.
        uint depositTime;       // first deposit time.
        uint timeDelta;         // seconds accounted for in fee calculation.
        uint deltaDays;         // days accounted for in fee calculation
    }

    // user info
    mapping (address => Users) public userInfo;

    // controls: emergencyWithdrawals.
    modifier emergencyActive {
        require(isEmergency, 'emergency mode is not active.');
        _;
    }

    // proxy for pausing contract.
    modifier isWithdrawable(uint amount) {
        require(startTime != 0, 'start time has not been set');
        require(amount > 0, 'cannot withdraw zero');
        require(startTime >= block.timestamp, 'rewards have not yet begun');
        require(isActivated, 'contract is currently paused');
        _;
    }
   
    // proxy for pausing contract.
    modifier isDepositable(uint amount) {
        require(startTime != 0, 'start time has not been set');
        require(amount > 0, 'cannot deposit zero');
        require(endTime < block.timestamp, 'the reward period has ended');
        require(isActivated, 'contract is currently paused');
        _;
    }

    // proxy for setting contract.
    modifier whileSettable {
        require(isSettable, 'contract is currently not settable');
        _;
    }

    // designates: soul access (for (rare) overrides).
    modifier onlySOUL() {
        require(soulDAO == msg.sender, "onlySOUL: caller is not the soulDAO address");
        _;
    }

    // ensures: only the DAO address is the sender.
    modifier onlyDAO() {
        require(DAO == msg.sender, "onlyDAO: caller is not the DAO address");
        _;
    }

    // ensures: only the Manifester address is the sender.
    modifier onlyManifester() {
        require(address(manifester) == msg.sender, "onlyManifester: caller is not the Manifester address");
        _;
    }

    event Harvested(address indexed user, uint amount, uint timestamp);
    event Deposited(address indexed user, uint amount, uint timestamp);
    event Manifested(string name, string symbol, address creatorAddress, address assetAddress, address depositAddress, address rewardAddress, uint timestamp);

    event Withdrawn(address indexed user, uint amount, uint feeAmount, uint timestamp);
    event EmergencyWithdrawn(address indexed user, uint amount, uint timestamp);
    event FeeDaysUpdated(uint feeDays);

    // sets the manifester at creation //
    constructor() {
        manifester = IManifester(msg.sender);
    }

    // initializes: manifestation by the manifester (at creation).
    function manifest(
        address _creatorAddress,
        address _assetAddress,
        address _depositAddress,
        address _rewardAddress
        ) external onlyManifester {
        require(!isManifested, 'initialize once');
        // sets: wnative and usdc address using manifester as ref.
        wnativeAddress = manifester.wnativeAddress();
        usdcAddress = manifester.usdcAddress();

        creatorAddress = _creatorAddress;
        assetAddress = _assetAddress;
        depositAddress = _depositAddress;
        rewardAddress = _rewardAddress;

        require(assetAddress == wnativeAddress || assetAddress == usdcAddress, 'must pair with native or stable asset');
        isNativePair = assetAddress == wnativeAddress;

        // sets: from input data.
        assetToken = IERC20(assetAddress);
        depositToken = IERC20(depositAddress);
        rewardToken = IERC20(rewardAddress);

        // sets: initial states.
        isManifested = true;
        isSettable = true;

        // sets: key data.
        soulDAO = manifester.soulDAO();
        wnativeAddress = manifester.wnativeAddress();
        nativeSymbol = manifester.nativeSymbol();
        
        // sets: assetSymbol s.t. [if] isNativePair [then] "NATIVE" [else] "STABLE".
        assetSymbol = isNativePair ? "NATIVE" : "STABLE";

        // constructs: name that corresponds to the rewardToken.
        name = string(abi.encodePacked('Manifest: ', ERC20(rewardAddress).name()));
        symbol = string(abi.encodePacked(ERC20(rewardAddress).symbol(), '-', assetSymbol, ' MP'));

        emit Manifested(name, symbol, creatorAddress, assetAddress, depositAddress, rewardAddress, block.timestamp);
    }
    
    function setRewards(uint _duraDays, uint _feeDays, uint _dailyReward) external {
        require(msg.sender == address(manifester), 'only the Manifester may set rewards');
        require(!isSetup, 'already setup');

        // sets: key info.
        duraDays = _duraDays;
        feeDays = toWei(_feeDays);
        dailyReward = toWei(_dailyReward);
        rewardPerSecond = toWei(_dailyReward) / 1 days;
        totalRewards = duraDays * toWei(_dailyReward);

        // sets: setup state.
        isSetup = true;
    }

    // updates: rewards, so that they are accounted for.
    function update() public {

        if (block.timestamp <= lastRewardTime) { return; }
        uint depositSupply = getTotalDeposit();

        // [if] first manifestationer, [then] set `lastRewardTime` to meow.
        if (depositSupply == 0) { lastRewardTime = block.timestamp; return; }

        // gets: multiplier from time elasped since pool began issuing rewards.
        uint multiplier = getMultiplier(lastRewardTime, block.timestamp);
        uint reward = multiplier * rewardPerSecond;

        accRewardPerShare += (reward * 1e12 / depositSupply);
        lastRewardTime = block.timestamp;
    }

    ///////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    ///////////////////////////////

    // returns: pending rewards for a specifed account.
    function getPendingRewards(address account) external view returns (uint pendingAmount) {
        // gets: pool and user data
        Users storage user = userInfo[account];

        // gets: `accRewardPerShare` & `lpSupply` (pool)
        uint _accRewardPerShare = accRewardPerShare; // uses: local variable for reference use.
        uint depositSupply = depositToken.balanceOf(address(this));

        // [if] holds deposits & rewards issued at least once (pool)
        if (block.timestamp > lastRewardTime && depositSupply != 0) {
            // gets: multiplier from the time since now and last time rewards issued (pool)
            uint multiplier = getMultiplier(lastRewardTime, block.timestamp);
            // get: reward as the product of the elapsed emissions and the share of soul rewards (pool)
            uint reward = multiplier * rewardPerSecond;
            // adds: product of reward and 1e12
            _accRewardPerShare = accRewardPerShare + reward * 1e12 / depositSupply;
        }

        // returns: rewardShare for user minus the amount paid out (user)
        pendingAmount = user.amount * _accRewardPerShare / 1e12 - user.rewardDebt;

        return pendingAmount;
    }

    // returns: multiplier during a period.
    function getMultiplier(uint from, uint to) public pure returns (uint multiplier) {
        multiplier = to - from;

        return multiplier;
    }

    // returns: price per token
    function getPricePerToken() public view returns (uint pricePerToken) {
        uint nativePriceUSD = uint(IManifester(manifester).getNativePrice());
        IERC20 WNATIVE = IERC20(wnativeAddress);
        uint wnativeBalance = WNATIVE.balanceOf(address(depositToken));
        uint totalSupply = depositToken.totalSupply();
        uint nativeValue = wnativeBalance * nativePriceUSD;
        pricePerToken = nativeValue * 2 / totalSupply;

        return pricePerToken;
    }

    // returns: TVL
    function getTVL() external view override returns (uint tvl) {
        uint pricePerToken = getPricePerToken();
        uint totalDeposited = getTotalDeposit();
        tvl = totalDeposited * pricePerToken;
        
        return tvl;
    }

    // returns: the total amount of deposited tokens.
    function getTotalDeposit() public view override returns (uint totalDeposited) {
        totalDeposited = depositToken.balanceOf(address(this));
        return totalDeposited;
    }

    // returns: user delta is the time since user either last withdrew OR first deposited OR 0.
	function getUserDelta(address account) public view returns (uint timeDelta) {
        // gets: stored `user` data.
        Users storage user = userInfo[account];

        // [if] has never withdrawn & has deposited, [then] returns: `timeDelta` as the seconds since first `depositTime`.
        if (user.withdrawTime == 0 && user.depositTime > 0) { return timeDelta = block.timestamp - user.depositTime; }
            // [else if] `user` has withdrawn, [then] returns: `timeDelta` as the time since the last withdrawal.
            else if(user.withdrawTime > 0) { return timeDelta = block.timestamp - user.withdrawTime; }
                // [else] returns: `timeDelta` as 0, since the user has never deposited.
                else return timeDelta = 0;
	}

    // gets: days based off a given timeDelta (seconds).
    function getDeltaDays(uint timeDelta) public pure returns (uint deltaDays) {
        deltaDays = timeDelta < 1 days ? 0 : timeDelta / 1 days;
        return deltaDays;     
    }

     // returns: feeRate and timeDelta.
    function getFeeRate(uint deltaDays) public view returns (uint feeRate) {
        // calculates: rateDecayed (converts to wei).
        uint rateDecayed = toWei(deltaDays);
    
        // [if] more time has elapsed than wait period
        if (rateDecayed >= feeDays) {
            // [then] set feeRate to 0.
            feeRate = 0;
        } else { // [else] reduce feeDays by the rateDecayed.
            feeRate = feeDays - rateDecayed;
        }

        return feeRate;
    }

    // returns: feeAmount and with withdrawableAmount for a given amount
    function getWithdrawable(
        uint deltaDays, 
        uint amount) public view returns (uint _feeAmount, uint _withdrawable) {
        // gets: feeRate
        uint feeRate = fromWei(getFeeRate(deltaDays));
        // gets: feeAmount
        uint feeAmount = (amount * feeRate) / 100;
        // calculates: withdrawable amount
        uint withdrawable = amount - feeAmount;

        return (feeAmount, withdrawable);
    }

    // returns: reward period (start, end).
    function getRewardPeriod() external view returns (uint start, uint end) {
        start = startTime;
        end = endTime;
        return (start, end);
    }

    //////////////////////////////////////
        /*/ ACCOUNT (TX) FUNCTIONS /*/
    //////////////////////////////////////

    // harvests: pending rewards.
    function harvest() external nonReentrant {
        Users storage user = userInfo[msg.sender];

        // updates: calculations.
        update();

        // gets: pendingRewards and requires pending reward.
        uint pendingReward = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        require(pendingReward > 0, 'there is nothing to harvest');

        // ensures: only a full payout is made, else fails.
        require(rewardToken.balanceOf(address(this)) >= pendingReward, 'insufficient balance for reward payout');
        
        // transfers: reward token to user.
        rewardToken.safeTransfer(msg.sender, pendingReward);

        // updates: reward debt (user).
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;

        emit Harvested(msg.sender, pendingReward, block.timestamp);

    }

    // deposit: tokens.
    function deposit(uint amount) external nonReentrant isDepositable(amount) {
        // gets: stored data for pool and user.
        Users storage user = userInfo[msg.sender];

        // updates: calculations.
        update();

        // [if] already deposited (user)
        if (user.amount > 0) {
            // [then] gets: pendingReward.
            uint pendingReward = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
                // [if] rewards pending, [then] transfer to user.
                if(pendingReward > 0) { 
                    // [then] ensures: only a full payout is made, else fails.
                    require(rewardToken.balanceOf(address(this)) >= pendingReward, 'insufficient balance for reward payout');
                    rewardToken.safeTransfer(msg.sender, pendingReward);
                }
        }

        // transfers: depositToken from user to contract
        depositToken.safeTransferFrom(address(msg.sender), address(this), amount);

        // adds: deposit amount (for user).
        user.amount += amount;

        // updates: reward debt (user).
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;

        // [if] first deposit
        if (user.depositTime == 0) {
            // [then] update depositTime
            user.depositTime = block.timestamp;
        }

        emit Deposited(msg.sender, amount, block.timestamp);
    }

    // withdraws: deposited tokens.
    function withdraw(uint amount) external nonReentrant isWithdrawable(amount) {
        // gets: stored data for the account.
        Users storage user = userInfo[msg.sender];

        require(user.amount >= amount, 'withdrawal exceeds deposit');
        
        // helps: manage calculations.
        update();

        // gets: pending rewards as determined by pendingSoul.
        uint pendingReward = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        // [if] rewards are pending, [then] send rewards to user.
        if(pendingReward > 0) { 
            // ensures: only a full payout is made, else fails.
            require(rewardToken.balanceOf(address(this)) >= pendingReward, 'insufficient balance for reward payout');
            rewardToken.safeTransfer(msg.sender, pendingReward); 
        }

        // gets: timeDelta as the time since last withdrawal.
        uint timeDelta = getUserDelta(msg.sender);

        // gets: deltaDays as days passed using timeDelta.
        uint deltaDays = getDeltaDays(timeDelta);

        // updates: deposit, timeDelta, & deltaDays (user)
        user.amount -= amount;
        user.timeDelta = timeDelta;
        user.deltaDays = deltaDays;

        // calculates: withdrawable amount (deltaDays, amount).
        (, uint withdrawableAmount) = getWithdrawable(deltaDays, amount); 

        // calculates: `feeAmount` as the `amount` requested minus `withdrawableAmount`.
        uint feeAmount = amount - withdrawableAmount;

        // transfers: `feeAmount` --> owner.
        rewardToken.safeTransfer(DAO, feeAmount);
        // transfers: withdrawableAmount amount --> user.
        rewardToken.safeTransfer(address(msg.sender), withdrawableAmount);

        // updates: rewardDebt and withdrawTime (user)
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;
        user.withdrawTime = block.timestamp;

        emit Withdrawn(msg.sender, amount, feeAmount, block.timestamp);
    }

    // enables: withdrawal without caring about rewards (for example, when rewards end).
    function emergencyWithdraw() external nonReentrant emergencyActive {
        // gets: pool & user data (to update later).
        Users storage user = userInfo[msg.sender];

        // helps: manage calculations.
        update();

        // transfers: depositToken to the user.
        depositToken.safeTransfer(msg.sender, user.amount);

        // eliminates: user deposit `amount` & `rewardDebt`.
        user.amount = 0;
        user.rewardDebt = 0;

        // updates: user `withdrawTime`.
        user.withdrawTime = block.timestamp;

        emit EmergencyWithdrawn(msg.sender, user.amount, user.withdrawTime);
    }

    ///////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    ///////////////////////////////
    
    // returns: key user info.
    function getUserInfo(address account) external view returns (uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        Users storage user = userInfo[account];
        return(user.amount, user.rewardDebt, user.withdrawTime, user.depositTime, user.timeDelta, user.deltaDays);
    }

    ////////////////////////////////
        /*/ ADMIN FUNCTIONS /*/
    ////////////////////////////////

    // enables: panic button (onlyDAO, whileSettable)
    function toggleEmergency(bool enabled) external onlyDAO whileSettable {
        isEmergency = enabled;
    }

    // toggles: pause state (onlyDAO, whileSettable)
    function toggleActive(bool enabled) external onlyDAO whileSettable {
        isActivated = enabled;
    }

    // updates: feeDays (onlyDAO, whileSettable) todo
    function setFeeDays(uint _feeDays) external onlyDAO whileSettable {
        // gets: current fee days & ensures distinction (pool)
        require(feeDays != toWei(_feeDays), 'no change requested');
        
        // limits: feeDays by default maximum of 30 days.
        require(toWei(_feeDays) <= toWei(30), 'exceeds a month of fees');
        
        // updates: fee days (pool)
        feeDays = toWei(_feeDays);
        
        emit FeeDaysUpdated(toWei(_feeDays));
    }

    // sets: startTime & endTime (onlyDAO)
    function setDelay(uint delayDays) external onlyDAO {
        require(startTime == 0, 'startTime has already been set');
        
        // converts: delayDays into a unix timeDelay variable (in seconds).
        uint timeDelay = delayDays * 1 days;

        // calculates: start (in seconds) as now + timeDelay.
        uint start = block.timestamp + timeDelay;
        
        // ensures: start time has not yet past.
        require(start > block.timestamp, 'start must be in the future');

        // calculates: duration (in seconds)
        uint duration = duraDays * 1 days;
        
        // sets: startTime.
        startTime = start;

        // sets: startTime.
        endTime = start + duration;
    }

    // sets: DAO address (onlyDAO)
    function setDAO(address _DAO) external onlyDAO {
        require(_DAO != address(0), 'cannot set to zero address');
        // updates: DAO adddress
        DAO = _DAO;
    }

    //////////////////////////////////////////
        /*/ SOUL (OVERRIDE) FUNCTIONS /*/
    //////////////////////////////////////////

    // prevents: funny business (onlySOUL).
    function toggleSettable(bool enabled) external onlySOUL {
        isSettable = enabled;
    }

    // overrides: feeDays (onlySOUL)
    function setFeeDaysOverride(uint _feeDays) external onlySOUL {
        // gets: current fee days & ensures distinction (pool)
        require(feeDays != toWei(_feeDays), 'no change requested');
        
        // limits: feeDays by default maximum of 30 days.
        require(toWei(_feeDays) <= toWei(30), 'exceeds a month of fees');
        
        // updates: fee days (pool)
        feeDays = toWei(_feeDays);
        
        emit FeeDaysUpdated(toWei(_feeDays));
    }

    // overrides: active state (onlySOUL).
    function toggleActiveOverride(bool enabled) external onlySOUL {
        isActivated = enabled;
    }

    // overrides logoURI (onlySOUL).
    function setLogoURI(string memory _logoURI) external onlySOUL {
        logoURI = _logoURI;
    }

    // sets: soulDAO address (onlySOUL).
    function setSoulDAO(address _soulDAO) external onlySOUL {
        require(_soulDAO != address(0), 'cannot set to zero address');
        // updates: soulDAO adddress
        soulDAO = _soulDAO;
    }

    ///////////////////////////////
        /*/ HELPER FUNCTIONS /*/
    ///////////////////////////////

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}
