// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import './Manifestation.sol';

contract Manifester is IManifester {
    using SafeERC20 for IERC20;
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(Manifestation).creationCode));

    ISoulSwapFactory public SoulSwapFactory;
    uint public totalManifestations;
    uint public totalEnchanters;
    uint public eShare;

    // enchanters are those who have been approved to be official referrers.
    struct Enchanters {
        address account;
        string voteHash;
        bool isActive;
    }

    // whitelist info
    Enchanters[] public eInfo;

    address[] public manifestations;
    address[] public daos;
    address[] public whitelist;

    address public override soulDAO;

    // immatable oracle constants
    IOracle private immutable nativeOracle;
    uint private immutable oracleDecimals;

    string public override nativeSymbol;
    address public override wnativeAddress;
    address public override usdcAddress;

    uint public bloodSacrifice;
    bool public isPaused;

    // creates: Manifestations struct (strictly immutable variables).
    struct Manifestations {
        address mAddress;
        address assetAddress;
        address depositAddress;
        address rewardAddress;
        address creatorAddress;
        address enchanterAddress;
    }

    // manifestation info
    Manifestations[] public mInfo;

    mapping(address => mapping(uint => address)) public getManifestation; // depositAddress, id

    event SummonedManifestation(
        uint indexed id,
        address indexed depositAddress, 
        address rewardAddress, 
        address creatorAddress,
        address enchanterAddress,
        address manifestation
    );

    event Paused(bool enabled, address msgSender);
    event Enchanted(uint id, address account, string voteHash, bool isActive);
    event UpdatedSacrifice(address msgSender);
    event UpdatedDAO(address msgSender);

    // proxy for pausing contract.
    modifier whileActive {
        require(!isPaused, 'contract is currently paused');
        _;
    }

    // restricts: certain functions to soulDAO-only.
    modifier onlySOUL() {
        require(soulDAO == msg.sender, "onlySOUL: caller is not the soulDAO address");
        _;
    }

    // restricts: only existing manifestations.
    modifier exists(uint id, uint total) {
        require(id <= total, 'does not exist.');
        _;
    }

    constructor(
        address _factoryAddress,
        address _usdcAddress,
        address _wnativeAddress,
        address _nativeOracle, 
        uint _oracleDecimals,
        string memory _nativeSymbol
    ) {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
        bloodSacrifice = toWei(2);
        nativeSymbol = _nativeSymbol;
        usdcAddress = _usdcAddress;
        wnativeAddress = _wnativeAddress;
        soulDAO = msg.sender;
        nativeOracle = IOracle(_nativeOracle);
        oracleDecimals = _oracleDecimals;

        // creates: Enchantress as the first Enchanter.
        eInfo.push(Enchanters({
            account: 0xFd63Bf84471Bc55DD9A83fdFA293CCBD27e1F4C8,
            voteHash: '0xBuns.com',
            isActive: true
        }));

        // increments: totalEnchanters.
        totalEnchanters ++;
    }

    // creates: Manifestation
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
        require(depositAddress != address(0), 'depositAddress must be SoulSwap LP');
        // ensures: unique depositAddress-id mapping.
        require(getManifestation[depositAddress][id] == address(0), 'reward already exists'); // single check is sufficient

        // generates: creation code, salt, then assembles a create2Address for the new manifestation.
        bytes memory bytecode = type(Manifestation).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(depositAddress, id));
        assembly { manifestation := create2(0, add(bytecode, 32), mload(bytecode), salt) }

        // populates: the getManifestation using the depositAddress and id.
        getManifestation[depositAddress][id] = manifestation;

        // stores the manifestation to the manifestations[] array
        manifestations.push(manifestation);

        // stores the dao to the daos[] array
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

        emit SummonedManifestation(id, depositAddress, rewardAddress, msg.sender, enchanterAddress, manifestation);
    }

    // initializes: manifestation
    function initializeManifestation(uint id) external exists(id, totalManifestations) {
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

    // launches: Manifestation.
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

        require(_launchManifestation(id, duraDays, feeDays, dailyReward, reward), 'launch failed.');
    }

    function _launchManifestation(uint id, uint duraDays, uint feeDays, uint dailyReward, uint reward) internal returns (bool) {
        // gets: stored enchanters info by id.
        Enchanters storage enchanter = eInfo[id];
        address eAddress = enchanter.account;

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
        IERC20(rewardAddress).safeTransferFrom(msg.sender, eAddress, toEnchanter);
        
        // transfers: share directly to soulDAO.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, soulDAO, toDAO);
        
        // transfers: `totalRewards` to the manifestation contract.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, mAddress, total);

        return true;
    }

    //////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    //////////////////////////////

    // returns: native price.
    function getNativePrice() public view override returns (int) {
        int latestAnswer = IOracle(nativeOracle).latestAnswer();
        return latestAnswer;
    }
   
    function getSplit(uint sacrifice) public view returns (uint toDAO, uint toEnchanter) {
        toEnchanter = sacrifice * eShare;
        toDAO = sacrifice - toEnchanter;
    }

    // returns: total rewards.
    function getTotalRewards(uint duraDays, uint dailyReward) public pure returns (uint) {
        uint totalRewards = duraDays * toWei(dailyReward);
        return totalRewards;
    }

    // returns: sacrifice amount.
    function getSacrifice(uint _rewards) public view returns (uint) {
        uint sacrifice = (_rewards * bloodSacrifice) / 100;
        return sacrifice;
    }

    // returns: info for a given id.
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

    // returns: user info for a given id.
    function getUserInfo(uint id, address account) external view returns (
        address mAddress, uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        mAddress = address(manifestations[id]);
        Manifestation manifestation = Manifestation(mAddress);
        (amount, rewardDebt, withdrawTime, depositTime, timeDelta, deltaDays) = manifestation.getUserInfo(account);
    }

    ///////////////////////////////
        /*/ ADMIN FUNCTIONS /*/
    ///////////////////////////////

    function addEnchanter(address _account, string calldata _voteHash) external onlySOUL {        
        // appends and populates: a new Enchanter struct (instance).
        eInfo.push(Enchanters({
            account: _account,        // address account;
            voteHash: _voteHash,      // string voteHash;
            isActive: true            // bool isActive;
        }));

        uint id = mInfo.length;
        totalEnchanters ++;

        emit Enchanted(id, _account, _voteHash, true);
    }

    function updateEnchanter(uint id, bool isActive) external onlySOUL exists(id, totalEnchanters) {
        // gets: stored data for enchanter.
        Enchanters storage enchanter = eInfo[id];
        // updates: isActive status.
        enchanter.isActive = isActive;
    }

    function updateFactory(address _factoryAddress) external onlySOUL {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
    }

    function updateDAO(address _soulDAO) external onlySOUL {
        soulDAO = _soulDAO;

        emit UpdatedDAO(msg.sender);
    }

    function updateEnchantShare(uint _share) external onlySOUL {
        eShare = _share;
    }

    function updateSacrifice(uint _sacrifice) external onlySOUL {
        bloodSacrifice = toWei(_sacrifice);

        emit UpdatedSacrifice(msg.sender);
    }

    function togglePause(bool enabled) external onlySOUL {
        isPaused = enabled;

        emit Paused(enabled, msg.sender);
    }


    ////////////////////////////////
        /*/ HELPER FUNCTIONS /*/
    ////////////////////////////////

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}