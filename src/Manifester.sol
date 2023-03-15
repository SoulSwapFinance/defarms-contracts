// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import './Manifestation.sol';

contract Manifester is IManifester {
    using SafeERC20 for IERC20;
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(Manifestation).creationCode));

    ISoulSwapFactory public SoulSwapFactory;
    uint public totalManifestations;
    uint public totalEnchanters;

    // approved enchanters.
    struct Enchanters {
        address account;
        bool isActive;
    }

    // [√] enchanters info.
    Enchanters[] public eInfo;

    address[] public manifestations;
    mapping(address => uint[]) public manifestationsByManifester; 

    // checks: whether already an enchanter.
    mapping(address => bool) public enchanted; 

    address public override soulDAO;

    string public override nativeSymbol;
    address public override wnativeAddress;
    address public override auraAddress;
    address public override usdcAddress;

    uint public override auraMinimum;
    uint public bloodSacrifice;
    bool public isPaused;

    // [.√.] creates: Manifestations struct (strictly immutable variables).
    struct Manifestations {
        address mAddress;
        address depositAddress;
        address rewardAddress;
        address creatorAddress;
        address enchanterAddress;
    }

    // [.√.] manifestation info
    Manifestations[] public mInfo;

    event SummonedManifestation(
        uint indexed id,
        address depositAddress, 
        address rewardAddress, 
        address creatorAddress,
        address enchanterAddress,
        address manifestation,
        string logoURI
    );

    event Paused(bool enabled);
    event Enchanted(uint id, address account, bool isActive);
    event UpdatedSacrifice(uint sacrifice);
    event UpdatedDAO(address dao);
    event DelaySet(uint id, address mAddress, address msgSender, uint delayDays);

    // [.√.] proxy for pausing contract.
    modifier whileActive {
        require(!isPaused, 'contract is currently paused');
        _;
    }

    // [.√.] restricts: certain functions to soulDAO-only.
    modifier onlySOUL() {
        require(soulDAO == msg.sender, "onlySOUL: caller is not the soulDAO address");
        _;
    }

    // [.√.] restricts: only existing manifestations and enchanters.
    modifier exists(uint id, uint total) {
        require(id <= total, 'does not exist.');
        _;
    }

    // [.√.] sets: key variables.
    constructor(
        address _factoryAddress,
        address _auraAddress,
        address _usdcAddress,
        address _wnativeAddress,
        address _enchantress,
        string memory _nativeSymbol
    ) {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
        // sets: sacrifice to 5%.
        bloodSacrifice = toWei(5);
        nativeSymbol = _nativeSymbol;
        // sets: key addresses.
        auraAddress = _auraAddress;
        usdcAddress = _usdcAddress;
        wnativeAddress = _wnativeAddress;
        soulDAO = msg.sender;

        // creates: the first Enchanter[0].
        addEnchanter(_enchantress);
    }

    // [.√.] creates: Manifestation
    function createManifestation(
        address rewardAddress,
        uint enchanterId,
        uint duraDays,
        uint feeDays,
        uint dailyReward,
        string memory logoURI
    ) external whileActive exists(enchanterId, totalEnchanters) returns (address manifestation, uint id) {
        // creates: id reference.
        id = manifestations.length;

        // creates: pair if doesn't exist.
        if (SoulSwapFactory.getPair(rewardAddress, wnativeAddress) == address(0)) {
            SoulSwapFactory.createPair(rewardAddress, wnativeAddress);
        }

        // gets: depositAddress.
        address depositAddress = SoulSwapFactory.getPair(rewardAddress, wnativeAddress);

        // ensures: depositAddress is never 0x.
        require(depositAddress != address(0), 'depositAddress must be SoulSwap LP.');

        // ensures: reward token has 18 decimals.
        require(ERC20(rewardAddress).decimals() == 18, 'reward must be 18 decimals.');

        // gets: stored enchanter info
        Enchanters memory enchanter = eInfo[enchanterId];

        // sets: enchanterAddress.
        address enchanterAddress = enchanter.account;

        // generates: creation code, salt, then assembles a create2Address for the new manifestation.
        manifestation = generateManifestation(depositAddress, id);

        // stores: manifestation to the manifestations[] array.
        manifestations.push(manifestation);

        // stores: manifested to the manifester[] array.
        manifestationsByManifester[address(this)].push(id);

        // increments: the total number of manifestations
        totalManifestations++;

        // appends and populates: a new Manifestations struct (instance).
        mInfo.push(Manifestations({
            mAddress: manifestations[id],
            depositAddress: depositAddress,
            rewardAddress: rewardAddress,
            creatorAddress: msg.sender,
            enchanterAddress: enchanterAddress
        }));

        _initializeManifestation(id, duraDays, feeDays, dailyReward, logoURI);
    
        emit SummonedManifestation(id, depositAddress, rewardAddress, msg.sender, enchanterAddress, manifestation, logoURI);
    }

    // [.√.] creates: Manifestation
    function createManifestationOverride(
        address depositAddress,
        address rewardAddress,
        uint enchanterId,
        uint duraDays,
        uint feeDays,
        uint dailyReward,
        string memory logoURI
    ) external whileActive onlySOUL exists(enchanterId, totalEnchanters) returns (address manifestation, uint id) {
        // creates: id reference.
        id = manifestations.length;

         // ensures: depositAddress is never 0x.
        require(depositAddress != address(0), 'depositAddress must be SoulSwap LP.');

        // ensures: reward token has 18 decimals.
        require(ERC20(rewardAddress).decimals() == 18, 'reward must be 18 decimals.');

        // gets: stored enchanter info
        Enchanters memory enchanter = eInfo[enchanterId];

        // sets: enchanterAddress.
        address enchanterAddress = enchanter.account;

        // generates: creation code, salt, then assembles a create2Address for the new manifestation.
        manifestation = generateManifestation(depositAddress, id);

        // stores manifestation to the manifestations[] array
        manifestations.push(manifestation);

        // increments: the total number of manifestations
        totalManifestations++;

        // appends and populates: a new Manifestations struct (instance).
        mInfo.push(Manifestations({
            mAddress: manifestations[id],
            depositAddress: depositAddress,
            rewardAddress: rewardAddress,
            creatorAddress: msg.sender,
            enchanterAddress: enchanterAddress
        }));

        _initializeManifestation(id, duraDays, feeDays, dailyReward, logoURI);
    
        emit SummonedManifestation(id, depositAddress, rewardAddress, msg.sender, enchanterAddress, manifestation, logoURI);
    }

    // [.√.] initializes: manifestation
    function _initializeManifestation(uint id, uint duraDays, uint feeDays, uint dailyReward, string memory logoURI) internal exists(id, totalManifestations) {
        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];

        // gets: associated variables by id.
        address mAddress = manifestations[id];
        address rewardAddress = manifestation.rewardAddress;
        address depositAddress = manifestation.depositAddress;

        // creates: new manifestation based off of the inputs, then stores as an array.
        Manifestation(mAddress).manifest(
            id,
            msg.sender,
            wnativeAddress,
            depositAddress,
            rewardAddress,
            logoURI
        );

        _launchManifestation(id, duraDays, feeDays, dailyReward);
    }

    // [.√.] sets: reward, sacrifice && transfers: reward fee split (DAO, Enchanter).
    function _launchManifestation(uint id, uint duraDays, uint feeDays, uint dailyReward) internal returns (bool) {

        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];
        
        // gets: distribution amounts.
        uint reward = getTotalRewards(duraDays, dailyReward);
        uint sacrifice = getSacrifice(fromWei(reward));
        (uint toDAO, uint toEnchanter) = getSplit(sacrifice);

        address rewardAddress = manifestation.rewardAddress;
        address mAddress = manifestations[id];

        uint total = getTotalRewards(duraDays, dailyReward) + sacrifice;

        // sets: the rewards data for the newly-created manifestation.
        Manifestation(mAddress).setRewards(duraDays, feeDays, dailyReward);
    
        // checks: the creator has a sufficient balance to cover both rewards + sacrifice.
        require(ERC20(rewardAddress).balanceOf(msg.sender) >= total, 'insufficient balance to launch manifestation.');

        // transfers: eShare directly to enchanter.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, manifestation.enchanterAddress, toEnchanter);
        
        // transfers: share directly to soulDAO.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, soulDAO, toDAO);
        
        // transfers: `totalRewards` to the manifestation contract.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, mAddress, total);

        return true;
    }

    //////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    //////////////////////////////

    // [.√.] returns: generated manifestation address.
    function generateManifestation(address depositAddress, uint id) public returns (address manifestation) {
        // generates: creation code, salt, then assembles a create2Address for the new manifestation.
        bytes memory bytecode = type(Manifestation).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(depositAddress, id));
        assembly { manifestation := create2(0, add(bytecode, 32), mload(bytecode), salt) }
    }

    // [.√.] returns: sacrificial split between DAO & enchanter.
    function getSplit(uint sacrifice) public pure returns (uint toDAO, uint toEnchanter) {
        toEnchanter = sacrifice / 5; // 80%
        toDAO = sacrifice - toEnchanter; // 20%
    }

    // [.√.] returns: total rewards.
    function getTotalRewards(uint duraDays, uint dailyReward) public pure returns (uint) {
        uint totalRewards = duraDays * toWei(dailyReward);
        return totalRewards;
    }

    // [.√.] returns: sacrifice amount.
    function getSacrifice(uint _rewards) public view returns (uint) {
        uint sacrifice = (_rewards * bloodSacrifice) / 100;
        return sacrifice;
    }

    // used for UIs.
    function getManifestationsByManifester(address _manifester) view external returns (uint[] memory) { 
        return manifestationsByManifester[_manifester]; 
    }

    // used for UIs.
    function getManifestations() view external returns (uint[] memory) { 
        return manifestationsByManifester[address(this)]; 
    }

    // [.√.] returns: info for a given id.
    function getInfo(uint id) external view returns (
        address mAddress,
        address daoAddress,
        string memory name, 
        string memory symbol, 
        string memory logoURI,

        address rewardAddress,
        address depositAddress,

        uint rewardPerSecond,
        uint rewardRemaining,
        uint startTime,
        uint endTime,
        uint dailyReward, 
        uint feeDays
        ) {
        // gets: stored manifestation info by id.
        mAddress = address(manifestations[id]);
        Manifestation m = Manifestation(mAddress);

        daoAddress = m.DAO();

        name = m.name();
        symbol = m.symbol();

        logoURI = m.logoURI();

        rewardAddress = m.rewardAddress();
        depositAddress = m.depositAddress();
    
        rewardPerSecond = m.rewardPerSecond();
        rewardRemaining = ERC20(rewardAddress).balanceOf(mAddress);

        startTime = m.startTime();
        endTime = m.endTime();
        dailyReward = m.dailyReward();
        feeDays = m.feeDays();
    }

    // [.√.] returns: user info for a given id.
    function getUserInfo(uint id, address account) external view returns (
        address mAddress, uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        mAddress = address(manifestations[id]);
        Manifestation manifestation = Manifestation(mAddress);
        (amount, rewardDebt, withdrawTime, depositTime, timeDelta, deltaDays) = manifestation.getUserInfo(account);
        return (mAddress, amount, rewardDebt, withdrawTime, depositTime, timeDelta, deltaDays);
    }

    // [.√.] sets: delay from Manifester --> Manifestation.
    function setDelay(uint id, uint delayDays) external {
        address mAddress = address(manifestations[id]);
        Manifestation manifestation = Manifestation(mAddress);
        // inputs: requestor, delayDays.
        manifestation.setDelay(msg.sender, delayDays);

        emit DelaySet(id, mAddress, msg.sender, delayDays);
    }

    ///////////////////////////////
        /*/ ADMIN FUNCTIONS /*/
    ///////////////////////////////

    // [.√.] adds: Enchanter (instance).
    function addEnchanter(address _account) public onlySOUL {     
        require(!enchanted[_account], "already enchanted");
        // appends and populates: a new Enchanter struct (instance).
        eInfo.push(Enchanters({
            account: _account,        // address account;
            isActive: true            // bool isActive;
        }));

        uint id = mInfo.length;
        // adds: account to enchanted array.
        enchanted[_account] = true;

        totalEnchanters ++;

        emit Enchanted(id, _account, true);
    }
    // [.√.] updates: Enchanter status.
    function updateEnchanter(uint enchanterId, bool isActive) external onlySOUL exists(enchanterId, totalEnchanters) {
        // gets: stored data for enchanter.
        Enchanters storage enchanter = eInfo[enchanterId];
        // updates: isActive status.
        enchanter.isActive = isActive;
    }

    // [.√.] updates: factory address.
    function updateFactory(address _factoryAddress) external onlySOUL {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
    }

    // [.√.] updates: soulDAO address.
    function setSoulDAO(address _soulDAO) external onlySOUL {
        soulDAO = _soulDAO;

        emit UpdatedDAO(_soulDAO);
    }

    // [.√.] updates: sacrifice amount.
    function updateSacrifice(uint _sacrifice) external onlySOUL {
        require(_sacrifice <= 100, 'exceeds 100%.');
        bloodSacrifice = toWei(_sacrifice);

        emit UpdatedSacrifice(_sacrifice);
    }

    // [.√.] updates: pause state.
    function togglePause(bool enabled) external onlySOUL {
        isPaused = enabled;

        emit Paused(enabled);
    }

    // [.√.] updates: minimum aura for deposits.
    function updateAuraMinimum(uint _minimumAura) external onlySOUL {
        require(auraMinimum != _minimumAura, 'no change.');
        auraMinimum = _minimumAura;
    }

    // [.√.] updates: aura address.
    function updateAuraAddress(address _auraAddress) external onlySOUL {
        require(auraAddress != _auraAddress, 'no change.');
        auraAddress = _auraAddress;
    }

    ////////////////////////////////
        /*/ HELPER FUNCTIONS /*/
    ////////////////////////////////

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}