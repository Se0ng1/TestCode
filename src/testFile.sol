// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./interfaces/ComptrollerInterface.sol";
import "./interfaces/CTokenInterface.sol";
import "forge-std/Test.sol";
import "./TestUtils.sol";

contract testComptroller is ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;
    function borrowCaps(address vToken) override external view returns (uint){}
    function getAccountLiquidity(address account) external override view returns (uint, uint, uint) {
    }
    function checkMembership(address account, address cToken) external view returns (bool){}
    function getHypotheticalAccountLiquidity(
        address account,
        address vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) override external view returns (uint256, uint256, uint256){}

    function enterMarkets(address[] memory cTokens) external override returns (uint256[] memory) {
    }
    function mintAllowed(address cToken, address minter, uint mintAmount) override external returns (uint){}
    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) override external returns (uint){}
    function borrowAllowed(address cToken, address borrower, uint borrowAmount) override external returns (uint){}
    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) override external returns (uint){}
    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) override external returns (uint){}

    function exitMarket(address) external override returns (uint){}

    function getAllMarkets() external override view returns (address[] memory){
    }

    function getAssetsIn(address account) external override view returns (address[] memory) {
    }

    function markets(address cToken) external override view returns (bool, uint256, bool) {

    }

    function closeFactorMantissa() external override view returns (uint) {
    }

    function liquidationIncentiveMantissa() external override view returns (uint){}
    
    function reserveFactorMantissa() external override view returns (uint) {
    }
    function borrowCapGuardian() external override view returns (address){
    }
    function pauseGuardian() external override view returns (address){
    }
    function mintGuardianPaused(address) external override returns (bool){
    }

    function borrowGuardianPaused(address) external override returns (bool){
    }

    function transferGuardianPaused() external override returns (bool){
    }

    function seizeGuardianPaused() external override returns (bool){
    }
    function compBorrowSpeeds(address) external override returns (uint){
    }
    function compSupplyState(address) external override returns (uint,uint){
    }

    function compBorrowState(address) external override returns (uint,uint){
    }

    function compSupplySpeeds(address) external override returns (uint){
    }
    function compContributorSpeeds(address) external override returns (uint){
    }
    function claimComp(address holder) override external{
    }
    function compAccrued(address) override external returns (uint){
    }
    function compSupplierIndex(address market, address supplier) override external returns (uint){
    }
    
    function compBorrowerIndex(address market, address borrower) override external returns (uint){
    }

    function updateContributorRewards(address contributor) override external{
    }

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount
    ) external override view returns (uint, uint) {
    }
    function _setPriceOracle(address newOracle) override external returns (uint){}

    function _setCloseFactor(uint newCloseFactorMantissa) override external returns (uint){}

    function _setCollateralFactor(CTokenInterface cToken, uint newCollateralFactorMantissa) override  external returns (uint){}

    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa)  override external returns (uint){}

    function _supportMarket(CTokenInterface cToken) override external returns (uint){}

    function _setBorrowCapGuardian(address newBorrowCapGuardian) override  external{}

    function _setPauseGuardian(address newPauseGuardian) override external returns (uint){}

    function _setMintPaused(CTokenInterface cToken, bool state) override external returns (bool){}

    function _setBorrowPaused(CTokenInterface cToken, bool state) override external returns (bool){}

    function _setTransferPaused(bool state) override external returns (bool){}

    function _setSeizePaused(bool state) override external returns (bool){}

    function _grantComp(address recipient, uint amount) override external{}

    function _setCompSpeeds(CTokenInterface[] memory cTokens, uint[] memory supplySpeeds, uint[] memory borrowSpeeds) override external{}

    function _setContributorCompSpeed(address contributor, uint compSpeed) override external{}

    function _become(address unitroller) override external{
        require(msg.sender == UnitrollerInterface(unitroller).admin(), "only unitroller admin can change brains");
        require(UnitrollerInterface(unitroller)._acceptImplementation() == 0, "change not authorized");
    }

    function _setMarketBorrowCaps(CTokenInterface[] calldata cTokens, uint[] calldata newBorrowCaps) override external{}

    function oracle() external returns(address){}
}


contract testInterestRateModel is InterestRateModel{
    function getBorrowRate(uint cash, uint borrows, uint reserves) override external view returns (uint){}
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) override external view returns (uint){}

}

contract testCToken is CTokenInterface{
    bool public constant isCToken = true;
    function balanceOf(address owner) override external view returns (uint256){}

    function balanceOfUnderlying(address owner) override external returns (uint256){}

    function getAccountSnapshot(address account) override external view returns (uint, uint, uint, uint){}

    function borrow(uint256 borrowAmount) override external returns (uint256){}
    
    function borrowIndex() override external returns (uint){}

    function borrowBalanceCurrent(address account) override external returns (uint256){}

    function decimals() override external view returns (uint256){}

    function exchangeRateCurrent() override external returns (uint256){}

    function getCash() override external view returns (uint256){}

    function mint(uint256 amount) override external returns (uint256){}

    function mint() override external payable{}

    function repayBorrow(uint256 amount) override external{}
    
    function repayBorrowBehalf(address borrower, uint256 amount) override external{}
    
    function repayBorrowBehalf(address borrower) override external payable{}

    function redeem(uint256 redeemTokens) override external returns (uint256){
    }

    function redeemUnderlying(uint256 redeemAmount) override external returns (uint256){}

    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) override external returns (uint){}

    function supplyRatePerBlock() override external view returns (uint256){}

    function transfer(address dst, uint256 amount) override external returns (bool){}

    function totalBorrowsCurrent() override external returns (uint256){}

    function totalReserves() override external view returns (uint256){}

    function totalSupply() override external view returns (uint256){}

    function pendingAdmin() override external  returns (address payable){}
    
    function admin() override external   returns (address payable){}
    
    function comptroller() override external   returns (address){}

    function reserveFactorMantissa() override external returns (uint){}

    function accrueInterest() override external returns (uint) {}

    
    function interestRateModel() override external returns (address){}

    function _addReserves(uint addAmount)  override external returns (uint){}

    function _addReserves() override external payable returns (uint){
    }

    function underlying() override external returns(address){}

    //admin function
    function _setPendingAdmin(address payable newPendingAdmin)  override external returns (uint){}
    
    function _acceptAdmin()  override external returns (uint){}
    
    function _setComptroller(ComptrollerInterface newComptroller)  override external returns (uint){}
    
    function _setReserveFactor(uint newReserveFactorMantissa)  override external returns (uint){}
    
    function _reduceReserves(uint reduceAmount)  override external returns (uint){}
    
    function _setInterestRateModel(InterestRateModel newInterestRateModel)  override external returns (uint){}
    
    function sweepToken(ERC20Interface token)  override external{}

    function implementation() override external returns(address){}
    
    //only cErc20delegate
    function _resignImplementation() override external{}
    function _becomeImplementation(bytes memory data)  override external{}
    
    //only cErc20delegator
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData)  override external{}

    function accrualBlockNumber() external override returns (uint){}
}

contract tools is Test, TestUtils{
    using stdStorage for StdStorage;
    testCToken deploy = new testCToken();
    CTokenInterface Not_registered_cToken= CTokenInterface(deploy);

    function set_pause() public{
        vm.startPrank(admin);
        comptroller._setMintPaused(cEther, true);
        comptroller._setMintPaused(cDai, true);
        
        comptroller._setBorrowPaused(cEther, true);
        comptroller._setBorrowPaused(cDai, true);

        comptroller._setMintPaused(cEther, true);
        comptroller._setMintPaused(cDai, true);

        comptroller._setSeizePaused(true);
        vm.stopPrank();
    }
    function set_unpause() public{
        vm.startPrank(admin);
        comptroller._setMintPaused(cEther, false);
        comptroller._setMintPaused(cDai, false);

        comptroller._setBorrowPaused(cEther, false);
        comptroller._setBorrowPaused(cDai, false);

        comptroller._setMintPaused(cEther, false);
        comptroller._setMintPaused(cDai, false);

        comptroller._setSeizePaused(false);
        vm.stopPrank();
    }
    function set_borrow_price_zero() public returns(uint){
        uint price = oracle.getUnderlyingPrice(address(cDai));
        vm.mockCall(
            address(oracle),
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(cDai)),
            abi.encode(0) 
        );
        return price;
    }
    function set_borrow_price_rollback(uint amount) public{
        vm.mockCall(
            address(oracle),
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(cDai)),
            abi.encode(amount) 
        );
    }
    function pass_accrueInterest() public{
        vm.mockCall(
            address(Not_registered_cToken),
            abi.encodeWithSelector(Not_registered_cToken.accrueInterest.selector),
            abi.encode(0)
        );
    }
}