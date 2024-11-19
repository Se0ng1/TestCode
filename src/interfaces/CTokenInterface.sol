// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./ComptrollerInterface.sol";
import "./ERC20Interface.sol";
interface CTokenInterface {
    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    
    function accrualBlockNumber() external returns (uint);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowIndex() external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function decimals() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function getCash() external view returns (uint256);

    function mint(uint256 amount) external returns (uint256);

    function mint() external payable; // cEther.

    function repayBorrow(uint256 amount) external;
    
    function repayBorrowBehalf(address borrower, uint256 amount) external;
    
    function repayBorrowBehalf(address borrower) external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);

    function supplyRatePerBlock() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function totalBorrowsCurrent() external returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function pendingAdmin() external  returns (address payable);
    
    function admin() external   returns (address payable); 
    
    function comptroller() external   returns (address); 

    function reserveFactorMantissa() external returns (uint);

    function accrueInterest() external returns (uint);
    
    function interestRateModel() external returns (address);

    function _addReserves(uint addAmount)  external returns (uint);

    function _addReserves() external payable returns (uint);

    function underlying() external returns(address);

    //admin function
    function _setPendingAdmin(address payable newPendingAdmin)  external returns (uint);
    
    function _acceptAdmin()  external returns (uint);
    
    function _setComptroller(ComptrollerInterface newComptroller)  external returns (uint);
    
    function _setReserveFactor(uint newReserveFactorMantissa)  external returns (uint);
    
    function _reduceReserves(uint reduceAmount)  external returns (uint);
    
    function _setInterestRateModel(InterestRateModel newInterestRateModel)  external returns (uint);
    
    function sweepToken(ERC20Interface token)  external;

    function implementation() external returns(address);
    
    //only cErc20delegate
    function _resignImplementation() external;
    function _becomeImplementation(bytes memory data)  external;
    
    //only cErc20delegator
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData)  external;
}

abstract contract InterestRateModel {
    bool public constant isInterestRateModel = true;

    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);
}

