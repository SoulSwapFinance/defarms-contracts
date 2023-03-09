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
    address[] public daos;
    // checks: whether already an enchanter.
    mapping(address => bool) public enchanted; 

    address public override soulDAO;

    // [..] immatable oracle constants
    IOracle private immutable nativeOracle;
    uint private immutable oracleDecimals;

    string public override nativeSymbol;
    address public override wnativeAddress;
    address public override usdcAddress;

    uint public bloodSacrifice;
    bool public isPaused;

    // [..] creates: Manifestations struct (strictly immutable variables).
    struct Manifestations {
        address mAddress;
        address assetAddress;
        address depositAddress;
        address rewardAddress;
        address creatorAddress;
        address enchanterAddress;
    }

    // [.√.] manifestation info
    Manifestations[] public mInfo;

    // [ .. ] depositAddress, id.
    // mapping(address => mapping(uint => address)) public getManifestation; 

    event SummonedManifestation(
        uint indexed id,
        address indexed depositAddress, 
        address rewardAddress, 
        address creatorAddress,
        address enchanterAddress,
        address manifestation
    );

    event Paused(bool enabled);
    event Enchanted(uint id, address account, bool isActive);
    event UpdatedSacrifice(uint sacrifice);
    event UpdatedDAO(address dao);

    // [..] proxy for pausing contract.
    modifier whileActive {
        require(!isPaused, 'contract is currently paused');
        _;
    }

    // [..] restricts: certain functions to soulDAO-only.
    modifier onlySOUL() {
        require(soulDAO == msg.sender, "onlySOUL: caller is not the soulDAO address");
        _;
    }

    // [..] restricts: only existing manifestations.
    modifier exists(uint id, uint total) {
        require(id <= total, 'does not exist.');
        _;
    }

    // [..] sets: key variables.
    constructor(
        address _factoryAddress,
        address _usdcAddress,
        address _wnativeAddress,
        address _nativeOracle, 
        uint _oracleDecimals,
        string memory _nativeSymbol
    ) {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
        // sets: sacrifice to 5%.
        bloodSacrifice = toWei(5);
        nativeSymbol = _nativeSymbol;

        usdcAddress = _usdcAddress;
        wnativeAddress = _wnativeAddress;

        soulDAO = msg.sender;
        nativeOracle = IOracle(_nativeOracle);
        oracleDecimals = _oracleDecimals;

        // creates: the first Enchanter[0].
        addEnchanter(msg.sender);

        // increments [+]: totalEnchanters.
        totalEnchanters ++;
    }

    // [.√.] creates: Manifestation
    function createManifestation(
        address depositAddress,
        address rewardAddress,
        uint enchanterId,
        bool isNative
        // address daoAddress
    ) external whileActive exists(enchanterId, totalEnchanters) returns (address manifestation, uint id) {
        // creates: id reference.
        id = manifestations.length;
        // gets: stored enchanter info
        Enchanters memory enchanter = eInfo[enchanterId];

        // sets: enchanterAddress.
        address enchanterAddress = enchanter.account;

        // sets: assetAddress.
        address assetAddress = isNative ? wnativeAddress : usdcAddress;

        // ensures: depositAddress is never 0x.
        require(depositAddress != address(0), 'depositAddress must be SoulSwap LP.');
        // ensures: reward token hasd 18 decimals.
        require(ERC20(rewardAddress).decimals() == 18, 'reward must be 18 decimals.');
        // ensures: unique depositAddress-id mapping.
        // require(getManifestation[depositAddress][id] == address(0), 'reward already exists'); // single check is sufficient

        // generates: creation code, salt, then assembles a create2Address for the new manifestation.
        bytes memory bytecode = type(Manifestation).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(depositAddress, id));
        assembly { manifestation := create2(0, add(bytecode, 32), mload(bytecode), salt) }

        // populates: the getManifestation using the depositAddress and id.
        // getManifestation[depositAddress][id] = manifestation;

        // stores manifestation to the manifestations[] array
        manifestations.push(manifestation);

        // stores: dao to the daos[] array
        daos.push(msg.sender);

        // increments: the total number of manifestations
        totalManifestations++;

        // appends and populates: a new Manifestations struct (instance).
        mInfo.push(Manifestations({
            mAddress: manifestations[id],
            assetAddress: assetAddress,
            depositAddress: depositAddress,
            rewardAddress: rewardAddress,
            creatorAddress: msg.sender,
            enchanterAddress: enchanterAddress
        }));

        _initializeManifestation(id);
    
        emit SummonedManifestation(id, depositAddress, rewardAddress, msg.sender, enchanterAddress, manifestation);
    }

    // [.√.] initializes: manifestation
    function _initializeManifestation(uint id) internal exists(id, totalManifestations) {
        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];

        // gets: associated variables by id.
        address mAddress = manifestations[id];
        address daoAddress = daos[id];
        address rewardAddress = manifestation.rewardAddress;
        address assetAddress = manifestation.assetAddress;
        address depositAddress = manifestation.depositAddress;

        // requires: sender is the DAO
        require(msg.sender == daoAddress, 'only the DAO may initialize');

        // creates: new manifestation based off of the inputs, then stores as an array.
        Manifestation(mAddress).manifest(
            daoAddress,
            assetAddress,
            depositAddress,
            rewardAddress
        );
    }

    // [.√.] launches: Manifestation.
    function launchManifestation(
        uint id,
        uint duraDays,
        uint dailyReward,
        uint feeDays
    ) external exists(id, totalManifestations) {
        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];

        // checks: the sender is the creator of the manifestation.
        require(msg.sender == manifestation.creatorAddress, 'only the creator may launch.');

        // gets: distribution amounts.
        uint reward = getTotalRewards(duraDays, dailyReward);

        require(_launch(id, duraDays, feeDays, dailyReward, reward), 'launch failed.');
    }

    function _launch(uint id, uint duraDays, uint feeDays, uint dailyReward, uint reward) internal returns (bool) {

        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];

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

    // [..] returns: native price.
    function getNativePrice() public view override returns (int) {
        int latestAnswer = IOracle(nativeOracle).latestAnswer();
        return latestAnswer;
    }

    // [.√.] returns: sacrificial split between DAO & enchanter.
    function getSplit(uint sacrifice) public pure returns (uint toDAO, uint toEnchanter) {
        toEnchanter = sacrifice / 5; // 80%
        toDAO = sacrifice - toEnchanter; // 20%
    }

    // [..] returns: total rewards.
    function getTotalRewards(uint duraDays, uint dailyReward) public pure returns (uint) {
        uint totalRewards = duraDays * toWei(dailyReward);
        return totalRewards;
    }

    // [.√.] returns: sacrifice amount.
    function getSacrifice(uint _rewards) public view returns (uint) {
        uint sacrifice = (_rewards * bloodSacrifice) / 100;
        return sacrifice;
    }

    // [..] returns: info for a given id.
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

    // [..] returns: user info for a given id.
    function getUserInfo(uint id, address account) external view returns (
        address mAddress, uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        mAddress = address(manifestations[id]);
        Manifestation manifestation = Manifestation(mAddress);
        (amount, rewardDebt, withdrawTime, depositTime, timeDelta, deltaDays) = manifestation.getUserInfo(account);
    }

    ///////////////////////////////
        /*/ ADMIN FUNCTIONS /*/
    ///////////////////////////////
    // [.√.] adds: Enchanter (instance).
    function addEnchanter(address _account) public onlySOUL {     
        require(!enchanted[_account], "already an enchanter");
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
    function updateEnchanter(uint id, bool isActive) external onlySOUL exists(id, totalEnchanters) {
        // gets: stored data for enchanter.
        Enchanters storage enchanter = eInfo[id];
        // updates: isActive status.
        enchanter.isActive = isActive;
    }

    // [.√.] updates: factory address.
    function updateFactory(address _factoryAddress) external onlySOUL {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
    }

    // [..] updates: soulDAO address.
    function updateDAO(address _soulDAO) external onlySOUL {
        soulDAO = _soulDAO;

        emit UpdatedDAO(_soulDAO);
    }

    // [..] updates: sacrifice amount.
    function updateSacrifice(uint _sacrifice) external onlySOUL {
        require(_sacrifice <= 100, 'cannot exceed 100%.');
        bloodSacrifice = toWei(_sacrifice);

        emit UpdatedSacrifice(_sacrifice);
    }

    // [.√.] updates: pause state.
    function togglePause(bool enabled) external onlySOUL {
        isPaused = enabled;

        emit Paused(enabled);
    }

    ////////////////////////////////
        /*/ HELPER FUNCTIONS /*/
    ////////////////////////////////

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}