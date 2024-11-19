// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "./interfaces/UnitrollerInterface.sol";
import {ComptrollerInterface} from "./interfaces/ComptrollerInterface.sol";
import {CTokenInterface} from "./interfaces/CTokenInterface.sol";
import {ERC20Interface} from "./interfaces/ERC20Interface.sol";
import {GovernorBravoInterface} from "./interfaces/GovernorBravoInterface.sol";
import {OracleInterface} from "./interfaces/OracleInterface.sol";
import {TimelockInterface} from "./interfaces/TimelockInterface.sol";

interface CheatCodes {
    function createFork(string calldata, uint256) external returns (uint256);
    function createSelectFork(string calldata, uint256) external returns (uint256);
    function startPrank(address) external;
    function stopPrank() external;
}

contract TestUtils is Test {
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /// @dev COMP token.
    ERC20Interface comp = ERC20Interface(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    /// @dev cEther compound.
    CTokenInterface cEther = CTokenInterface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    /// @dev cDai compound.
    CTokenInterface cDai = CTokenInterface(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    /// @dev cUSDC compound 
    CTokenInterface cLINK = CTokenInterface(0xFAce851a4921ce59e912d19329929CE6da6EB0c7);

    /// @dev Main governance contract.
    GovernorBravoInterface gBravo = GovernorBravoInterface(0xc0Da02939E1441F497fd74F78cE7Decb17B66529);

    /// @dev The Timelock.
    TimelockInterface timelock = TimelockInterface(0x6d903f6003cca6255D85CcA4D3B5E5146dC33925);

    /// @dev The comptroller.
    /// @dev This contract is actually the Unitroller that delegates calls to the Comptroller.
    ComptrollerInterface comptroller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /// @dev Dai.
    ERC20Interface dai = ERC20Interface(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    /// @dev link
    ERC20Interface link = ERC20Interface(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    
    address admin =0x6d903f6003cca6255D85CcA4D3B5E5146dC33925;

    UnitrollerInterface unitroller =UnitrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    /// @dev The oracle to get a token's price.
    OracleInterface oracle = OracleInterface(0x8CF42B08AD13761345531b839487aA4d113955d9);

    /// @dev We are forking mainnet at this block number for all test cases.
    uint256 public constant BLOCK_NUMBER = 20_941_968;
}
