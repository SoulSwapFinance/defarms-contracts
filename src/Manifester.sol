// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './Manifestation.sol';

contract Manifester is IManifester {
    using SafeERC20 for IERC20;
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(Manifestation).creationCode));

    ISoulSwapFactory public SoulSwapFactory;
    uint256 public totalManifestations;

    address[] public manifestations;
    address[] public daos;

    address public override soulDAO;

    IOracle public nativeOracle;
    uint public oracleDecimals;

    string public override nativeSymbol;
    address public override wnativeAddress;
    address public override usdcAddress;

    uint public bloodSacrifice;
    bool public isPaused;

    struct Manifestations {
        address mAddress;
        address rewardAddress;
        address depositAddress;
        address daoAddress;
        uint duraDays;
        uint feeDays;
        uint dailyReward;
    }

    // manifestation info
    Manifestations[] public mInfo;

    mapping(address => mapping(uint => address)) public getManifestation; // depositAddress, id

    event SummonedManifestation(
        uint indexed id,
        address indexed depositAddress, 
        address rewardAddress, 
        address creatorAddress, 
        address manifestation
    );

    event Paused(address msgSender);
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
    modifier exists(uint id) {
        require(id <= totalManifestations, 'manifestation (id) does not exist.');
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
        bloodSacrifice = toWei(1);
        nativeSymbol = _nativeSymbol;           // 'FTM';
        usdcAddress = _usdcAddress;             // = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
        wnativeAddress = _wnativeAddress;       // = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        soulDAO = msg.sender;
        nativeOracle = IOracle(_nativeOracle);  // = IOracle(0xf4766552D15AE4d256Ad41B6cf2933482B0680dc);
        oracleDecimals = _oracleDecimals;       // nativeOracle.decimals();
    }

    // creates: Manifestation
    function createManifestation(
        address rewardAddress, 
        address depositAddress,
        address daoAddress,
        uint duraDays,
        uint feeDays,
        uint dailyReward
        // address daoAddress
    ) external whileActive returns (address manifestation, uint id) {
        // creates: id reference.
        id = manifestations.length;

        // ensures: depositAddress is never 0x.
        require(depositAddress != address(0), 'depositAddress must be SoulSwap LP');
        // ensures: unique depositAddress-id mapping.
        require(getManifestation[depositAddress][id] == address(0), 'reward already exists'); // single check is sufficient

        // generates the creation code, salt, then assembles a create2Address for the new manifestation.
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
            rewardAddress: rewardAddress,
            depositAddress: depositAddress,
            daoAddress: daoAddress,
            duraDays: duraDays,
            feeDays: feeDays,
            dailyReward: dailyReward
        }));

        emit SummonedManifestation(id, depositAddress, rewardAddress, daoAddress, manifestation);
    }

    // initializes: manifestation
    function initializeManifestation(uint id) external exists(id) {
        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];

        // gets: associated variables by id.
        address mAddress = manifestations[id];
        address daoAddress = daos[id];
        address rewardAddress = manifestation.rewardAddress;
        address depositAddress = manifestation.depositAddress;

        // requires: sender is the DAO
        require(msg.sender == daoAddress, "only the DAO may initialize");

        // creates: new manifestation based off of the inputs, then stores as an array.
        Manifestation(mAddress).manifest(
            rewardAddress,
            depositAddress
            // daoAddress
            // address(this)
        );
    }

    // launches: Manifestation.
    function launchManifestation(
        uint id,
        uint duraDays,
        uint dailyReward,
        uint feeDays
    ) external exists(id) {
        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];
        require(msg.sender == manifestation.daoAddress, 'only the DAO may launch');

        uint reward = getTotalRewards(duraDays, dailyReward);
        uint sacrifice = getSacrifice(fromWei(reward));
        uint total = reward + sacrifice;

        address rewardAddress = manifestation.rewardAddress;
        address mAddress = manifestations[id];

        // sets: the rewards data for the newly-created manifestation.
        Manifestation(mAddress).setRewards(duraDays, feeDays, dailyReward);
    
        // checks: the creator has a sufficient balance to cover both rewards + sacrifice.
        require(ERC20(rewardAddress).balanceOf(msg.sender) >= total, 'insufficient balance to launch manifestation');

        // transfers: sacrifice directly to soulDAO.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, soulDAO, sacrifice);
        
        // transfers: `totalRewards` to the manifestation contract.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, mAddress, reward);
    }

    //////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    //////////////////////////////

    // returns: native price.
    function getNativePrice() public view override returns (int) {
        int latestAnswer = IOracle(nativeOracle).latestAnswer();
        return latestAnswer;
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
        uint feeDays) {

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

    function updateFactory(address _factoryAddress) external onlySOUL {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
    }

    function updateDAO(address _soulDAO) external onlySOUL {
        soulDAO = _soulDAO;

        emit UpdatedDAO(msg.sender);
    }

    function updateSacrifice(uint _sacrifice) external onlySOUL {
        bloodSacrifice = toWei(_sacrifice);

        emit UpdatedSacrifice(msg.sender);
    }

    function togglePause(bool enabled) external onlySOUL {
        isPaused = enabled;

        emit Paused(msg.sender);
    }


    ////////////////////////////////
        /*/ HELPER FUNCTIONS /*/
    ////////////////////////////////

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}