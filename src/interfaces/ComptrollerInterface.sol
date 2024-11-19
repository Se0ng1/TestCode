// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "./CTokenInterface.sol";
import "./UnitrollerInterface.sol";

interface ComptrollerInterface {
    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);
    
    function getHypotheticalAccountLiquidity(
        address account,
        address vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external view returns (uint256, uint256, uint256);

    function borrowCaps(address vToken) external view returns (uint);
    function checkMembership(address account, address cToken) external view returns (bool);

    function exitMarket(address) external returns (uint);
    
    function getAllMarkets() external view returns (address[] memory);
    
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

    function getAssetsIn(address acount) external view returns (address[] memory);

    function markets(address cToken) external view returns (bool, uint256, bool);

    function closeFactorMantissa() external view returns (uint);
    
    function reserveFactorMantissa() external view returns (uint);

    function liquidationIncentiveMantissa() external view returns (uint);

    function borrowCapGuardian() external view returns (address);

    function pauseGuardian() external view returns (address);

    function mintGuardianPaused(address) external returns (bool);

    function borrowGuardianPaused(address) external returns (bool);

    function transferGuardianPaused() external returns (bool);

    function seizeGuardianPaused() external returns (bool);
    
    function compSupplyState(address) external returns (uint,uint);

    function compBorrowState(address) external returns (uint,uint);

    function compBorrowSpeeds(address) external returns (uint);

    function compSupplySpeeds(address) external returns (uint);
    
    function compContributorSpeeds(address) external returns (uint);
    
    function claimComp(address holder) external;

    function compAccrued(address) external returns (uint);

    function compSupplierIndex(address market, address supplier) external returns (uint);
    
    function compBorrowerIndex(address market, address borrower) external returns (uint);
    
    function updateContributorRewards(address contributor) external;

    function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint repayAmount) external view returns (uint, uint);

    function mintAllowed(address cToken, address minter, uint mintAmount)  external returns (uint);
    function redeemAllowed(address cToken, address redeemer, uint redeemTokens)  external returns (uint);
    function borrowAllowed(address cToken, address borrower, uint borrowAmount)  external returns (uint);
    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount)  external returns (uint);
    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount)  external returns (uint);

    //admin function
    function _setPriceOracle(address newOracle) external returns (uint);

    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint);

    function _setCollateralFactor(CTokenInterface cToken, uint newCollateralFactorMantissa) external returns (uint);

    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint);

    function _supportMarket(CTokenInterface cToken) external returns (uint);

    function _setBorrowCapGuardian(address newBorrowCapGuardian) external;

    function _setPauseGuardian(address newPauseGuardian) external returns (uint);

    function _setMintPaused(CTokenInterface cToken, bool state) external returns (bool);

    function _setBorrowPaused(CTokenInterface cToken, bool state) external returns (bool);

    function _setTransferPaused(bool state) external returns (bool);

    function _setSeizePaused(bool state) external returns (bool);

    function _grantComp(address recipient, uint amount) external;

    function _setCompSpeeds(CTokenInterface[] memory cTokens, uint[] memory supplySpeeds, uint[] memory borrowSpeeds) external;

    function _setContributorCompSpeed(address contributor, uint compSpeed) external;

    function _become(address unitroller) external;

    function _setMarketBorrowCaps(CTokenInterface[] calldata cTokens, uint[] calldata newBorrowCaps) external;

    function oracle() external returns(address);

}
