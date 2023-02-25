// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


interface ISoulSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event SetFeeTo(address indexed user, address indexed _feeTo);
    event SetMigrator(address indexed user, address indexed _migrator);
    event FeeToSetter(address indexed user, address indexed feeToSetter);

    function feeTo() external view returns (address _feeTo);
    function feeToSetter() external view returns (address _fee);
    function migrator() external view returns (address _migrator);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setMigrator(address) external;
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IManifestation {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function logoURI() external returns (string memory);

    function depositAddress() external returns (address);
    function rewardAddress() external returns (address);

    function startTime() external returns (uint);
    function endTime() external returns (uint);

    function getTVL() external returns (uint);
    function getTotalDeposit() external returns (uint);
}

interface IManifester {
    function soulDAO() external returns (address);
    function wnativeAddress() external returns (address);
    function nativeSymbol() external returns (string memory);
    function getNativePrice() external view returns (int);
}


interface IOracle {
  function latestAnswer() external view returns (int256);
  function decimals() external view returns (uint8);
  function latestTimestamp() external view returns (uint256);
}
