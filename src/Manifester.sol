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
    address[] public rewards;
    address[] public deposits;
    address public override soulDAO;

    IOracle public nativeOracle;
    uint public oracleDecimals;

    string public override nativeSymbol;
    address public override wnativeAddress;

    uint public bloodSacrifice;
    bool public isPaused;

    // todo: create: Manifestations struct //
    struct Manifestations {
        address mAddress;
        address rewardAddress;
        address depositAddress;
        address daoAddress;
        // uint duraDays;
        // uint feeDays;
        // uint dailyReward;
    }

    // manifestation info
    Manifestations[] public mInfo;


    mapping(address => mapping(uint => address)) public getManifestation; // creatorAddress, id

    event SummonedManifestation(
        uint indexed id,
        address indexed creatorAddress, 
        address rewardAddress, 
        address depositAddress, 
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

    constructor(
        address _wnativeAddress, 
        address _nativeOracle, 
        uint _oracleDecimals,
        string memory _nativeSymbol
    ) {
        SoulSwapFactory = ISoulSwapFactory(0x1120e150dA9def6Fe930f4fEDeD18ef57c0CA7eF);
        bloodSacrifice = toWei(1);
        nativeSymbol = _nativeSymbol; // 'FTM';
        wnativeAddress = _wnativeAddress; // = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        soulDAO = msg.sender;
        nativeOracle = IOracle(_nativeOracle); // = IOracle(0xf4766552D15AE4d256Ad41B6cf2933482B0680dc);
        oracleDecimals = _oracleDecimals; // nativeOracle.decimals();
    }

    function createManifestation(
        address rewardAddress, 
        address depositAddress
        // address daoAddress
    ) external whileActive returns (address manifestation, uint id) {
        // address depositAddress = SoulSwapFactory.getPair(wnativeAddress, rewardAddress);
        // ensures: reward token has 18 decimals, which is needed for reward calculations.
        // require(ERC20(rewardAddress).decimals() == 18, 'reward token must be 18 decimals'); // todo: ensure safe

        // [if] pair does not exist
        // if (depositAddress == address(0)) {
        //     // [then] creates: pair and stores as depositAddress.
        //     createDepositToken(rewardAddress);
        //     depositAddress = SoulSwapFactory.getPair(wnativeAddress, rewardAddress);
        // }

        // creates: variables for usage.
        id = manifestations.length;
        // uint rewards = getTotalRewards(duraDays, dailyReward);
        // uint sacrifice = getSacrifice(fromWei(rewards));
        // uint total = rewards + sacrifice;

        // ensures: depositAddress is never 0x.
        require(depositAddress != address(0), 'depositAddress must be SoulSwap LP');
        // ensures: unique depositAddress-id mapping.
        require(getManifestation[msg.sender][id] == address(0), 'reward already exists'); // single check is sufficient
        
        // generates the creation code, salt, then assembles a create2Address for the new manifestation.
        bytes memory bytecode = type(Manifestation).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(depositAddress, id));
        assembly { manifestation := create2(0, add(bytecode, 32), mload(bytecode), salt) }

        // populates: the getManifestation mapping.
        getManifestation[msg.sender][id] = manifestation;

        // stores the manifestation to the manifestations[] array
        manifestations.push(manifestation);

        // stores the dao to the daos[] array
        daos.push(msg.sender);
        
        // stores the rewards to the daos[] array
        rewards.push(rewardAddress);

        // stores the deposits to the daos[] array
        deposits.push(depositAddress);

        // increments: the total number of manifestations
        totalManifestations++;

        // appends and populates: a new Manifestations struct (instance).
        mInfo.push(Manifestations({
            mAddress: manifestations[id],
            rewardAddress: rewardAddress,
            depositAddress: depositAddress,
            daoAddress: daos[id]
            // duraDays;
            // feeDays;
            // dailyReward;
        }));

        // _initializeManifestation(rewardAddress, depositAddress, msg.sender, manifestation);

        emit SummonedManifestation(id, msg.sender, rewardAddress, depositAddress, manifestation);
    }

    // initializes manifestation
    function initializeManifestation(
        uint id
        // address _rewardAddress,
        // address _depositAddress
    ) external {
        // gets: associated stored variables from the struct
        // Manifestations storage manifestation = mInfo[id];
        // references: associated daoAddress //
        // address mAddress_ = manifestation.mAddress;
        // address rewardAddress_ = manifestation.rewardAddress;
        // address depositAddress_ = manifestation.depositAddress;
        // address daoAddress_ = manifestation.daoAddress;

        // gets: associated variables from manifestation
        address mAddress = manifestations[id];
        address daoAddress = daos[id];
        address rewardAddress = rewards[id];
        address depositAddress = deposits[id];
        // address rewardAddress = Manifestation(mAddress).rewardAddress();
        // address depositAddress = Manifestation(mAddress).depositAddress();

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

    // function launchManifestation(
    //     uint id,
    //     uint duraDays,
    //     uint dailyReward,
    //     uint feeDays
    // ) public {
    //     // uint rewards = getTotalRewards(duraDays, dailyReward);
    //     // uint sacrifice = getSacrifice(fromWei(rewards));
    //     // uint total = rewards + sacrifice;
    //     address mAddress = manifestations[id];
    //     (address depositAddress, address rewardAddress) = getTokens(id);

    //     // require(getManifestation[msg.sender][id] != address(0), 'manifestation invalid');

    //     // creates: new manifestation based off of the inputs, then stores as an array.
    //     Manifestation(mAddress).manifest(rewardAddress, depositAddress, msg.sender, address(this));

    //     address daoAddress = getDAO[depositAddress][id];
    //     require(msg.sender == daoAddress, 'only the DAO may launch');

    //     // sets: the rewards data for the newly-created manifestation.
    //     Manifestation(mAddress).setRewards(duraDays, feeDays, dailyReward);
    
    //     // checks: the creator has a sufficient balance to cover both rewards + sacrifice. // todo: re-enable
    //     // require(ERC20(rewardAddress).balanceOf(msg.sender) >= total, 'insufficient balance to launch manifestation');

    //     // transfers: sacrifice directly to soulDAO.
    //     // IERC20(rewardAddress).safeTransferFrom(msg.sender, soulDAO, sacrifice); // todo: re-enable
        
    //     // transfers: `totalRewards` to the manifestation contract.
    //     // IERC20(rewardAddress).safeTransferFrom(msg.sender, mAddress, rewards); // todo: re-enable

    // }

    // creates: deposit token (as reward-native pair).
    function getTokens(uint id) public view returns (address depositAddress, address rewardAddress) {
        address mAddress = manifestations[id];
        depositAddress = Manifestation(mAddress).depositAddress();
        rewardAddress = Manifestation(mAddress).rewardAddress();
    }

    // creates: deposit token (as reward-native pair).
    // function createDepositToken(address rewardAddress) public {
    //     SoulSwapFactory.createPair(wnativeAddress, rewardAddress);
    // }

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
        mAddress = address(manifestations[id]);
        daoAddress = address(daos[id]);
        Manifestation manifestation = Manifestation(mAddress);

        name = manifestation.name();
        symbol = manifestation.symbol();

        logoURI = manifestation.logoURI();

        rewardAddress = manifestation.rewardAddress();
        depositAddress = manifestation.depositAddress();
    
        rewardPerSecond = manifestation.rewardPerSecond();
        rewardRemaining = ERC20(rewardAddress).balanceOf(mAddress);

        startTime = manifestation.startTime();
        endTime = manifestation.endTime();
        dailyReward = manifestation.dailyReward();
        feeDays = manifestation.feeDays();
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