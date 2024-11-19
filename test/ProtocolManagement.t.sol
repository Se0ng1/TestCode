pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/TestFile.sol";

/// @notice Example contract that calculates the account liquidity.
contract ProtocolManagementTest is Test, TestUtils {
    address payable user =payable(makeAddr('user'));
    address pauseGuardian;
    address borrowCapGuardian;

    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        pauseGuardian = comptroller.pauseGuardian();
        borrowCapGuardian = comptroller.borrowCapGuardian();
    }
    function test_setPriceOracle() public {
        vm.startPrank(admin);
        comptroller._setPriceOracle(address(0x1));
        assertEq(comptroller.oracle(), address(0x1));
        vm.stopPrank();
        
        //return errorcode
        uint result = comptroller._setPriceOracle(address(0x1));
        // emit Failure(: 1, : 16, : 0) 1 => UNAUTHORIZED, 16 => SET_PRICE_ORACLE_OWNER_CHECK
        assertEq(result, 1);
    }
    function test_setCloseFactor() public {
        vm.startPrank(admin);
        comptroller._setCloseFactor(1e18);
        assertEq(comptroller.closeFactorMantissa(), 1e18);
        vm.stopPrank();
        
        vm.expectRevert("only admin can set close factor");
        comptroller._setCloseFactor(1e18);
    }
    function test_setCollateralFactor() public {
        vm.startPrank(admin);
        (,uint collateralFactor,)=comptroller.markets(address(cEther));
        comptroller._setCollateralFactor(cEther, collateralFactor + 1);
        
        //return errorcode
        uint result = comptroller._setCollateralFactor(cEther, 0.9e18 + 1);
        // 6 => INVALID_COLLATERAL_FACTOR  8 => SET_COLLATERAL_FACTOR_VALIDATION
        assertEq(result,6);
        
        //return errorcode
        result = comptroller._setCollateralFactor(CTokenInterface(address(0x1)), 0.9e18 + 1);
        // emit Failure(: 9, : 7, : 0) 9 => MARKET_NOT_LISTED  7 => SET_COLLATERAL_FACTOR_NO_EXISTS
        assertEq(result,9);

        //set Ether price 0
        vm.mockCall(
            address(oracle),
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(cEther)),
            abi.encode(0) 
        );
        //return errorcode
        result = comptroller._setCollateralFactor(cEther, 1);
        //emit Failure(: 13, : 9, : 0) 13 => PRICE_ERROR, 9 => SET_COLLATERAL_FACTOR_WITHOUT_PRICE
        assertEq(result,13);
        vm.stopPrank();
        
        //return errorcode
        result = comptroller._setCollateralFactor(cEther, collateralFactor+1);
        // 1 => UNAUTHORIZED  6 => SET_COLLATERAL_FACTOR_OWNER_CHECK
        assertEq(result,1);
    }
    
    function test_setLiquidationIncentive() public {
        vm.startPrank(admin);
        comptroller._setLiquidationIncentive(1);
        assertEq(comptroller.liquidationIncentiveMantissa(), 1);

        vm.stopPrank();
        //return errorcode
        uint result = comptroller._setLiquidationIncentive(1);
        //emit Failure(: 1, : 11, : 0) 1 => FailureInfo  11=> SET_LIQUIDATION_INCENTIVE_OWNER_CHECK
        assertEq(result ,1);
    }

    function test_supportMarket() public {
        vm.startPrank(admin);

        testCToken deploy = new testCToken();
        CTokenInterface newCToken = CTokenInterface(deploy);

        comptroller._supportMarket(newCToken);

        //return errorcode
        uint result = comptroller._supportMarket(cEther);
        //emit Failure(: 10, : 17, : 0) 10 => MARKET_ALREADY_LISTED, 17 => SUPPORT_MARKET_EXISTS
        assertEq(result,10);
        
        vm.expectRevert();
        comptroller._supportMarket(CTokenInterface(address(1)));
        
        vm.stopPrank();
        
        //return errorcode
        result= comptroller._supportMarket(newCToken);
        //emit Failure(: 1, : 18, : 0) 1=> UNAUTHORIZED, 18 => SUPPORT_MARKET_OWNER_CHECK
        assertEq(result, 1);
    }
    function test_setMarketBorrowCaps() public {
        CTokenInterface[] memory cTokens =new CTokenInterface[](1);
        cTokens[0]=cEther;
        uint[] memory newBorrowCaps = new uint[](1);
        newBorrowCaps[0]=1e18;

        uint[] memory wrongBorrowCaps = new uint[](2);
        wrongBorrowCaps[0]=1e18;
        wrongBorrowCaps[1]=2e18;
        
        vm.startPrank(admin);
        comptroller._setMarketBorrowCaps(cTokens, newBorrowCaps);

        vm.expectRevert("invalid input");
        comptroller._setMarketBorrowCaps(cTokens, wrongBorrowCaps);
        
        vm.stopPrank();

        vm.expectRevert("only admin or borrow cap guardian can set borrow caps");
        comptroller._setMarketBorrowCaps(cTokens, newBorrowCaps);
    }

    function test_setBorrowCapGuardian() public {
        
        vm.startPrank(admin);
        comptroller._setBorrowCapGuardian(user);
        assertEq(comptroller.borrowCapGuardian(),user);
        vm.stopPrank();

        vm.expectRevert("only admin can set borrow cap guardian");
        comptroller._setBorrowCapGuardian(user);

    }
    function test_setPauseGuardian() public {
        vm.startPrank(admin);
        comptroller._setPauseGuardian(user);
        assertEq(comptroller.pauseGuardian(),user);
        vm.stopPrank();
        //return errorcode
        uint result = comptroller._setPauseGuardian(user);  
        //emit Failure(: 1, : 19, : 0) 1=> UNAUTHORIZED 19 => SET_PAUSE_GUARDIAN_OWNER_CHECK
        assertEq(result, 1);
    }
    function test_setMintPaused() public {
        vm.startPrank(admin);
        comptroller._setMintPaused(cEther, true);
        bool state = comptroller.mintGuardianPaused(address(cEther));
        assertEq(state,true);
        
        comptroller._setMintPaused(cEther, false);
        state = comptroller.mintGuardianPaused(address(cEther));
        assertEq(state,false);
        vm.stopPrank();

        vm.expectRevert("only pause guardian and admin can pause");
        comptroller._setMintPaused(cEther, true);
    }
    function test_setBorrowPaused() public {
        vm.startPrank(admin);
        comptroller._setBorrowPaused(cEther, true);
        bool state = comptroller.borrowGuardianPaused(address(cEther));
        assertEq(state,true);
        
        comptroller._setBorrowPaused(cEther, false);
        state = comptroller.borrowGuardianPaused(address(cEther));
        assertEq(state,false);
        vm.stopPrank();
        
        vm.expectRevert("only pause guardian and admin can pause");
        comptroller._setBorrowPaused(cEther, true);
    }
    function test_setTransferPaused() public {
        vm.startPrank(admin);
        comptroller._setTransferPaused(true);
        bool state = comptroller.transferGuardianPaused();
        assertEq(state,true);
        
        comptroller._setTransferPaused(false);
        state = comptroller.transferGuardianPaused();
        assertEq(state,false);
        vm.stopPrank();
        
        vm.expectRevert("only pause guardian and admin can pause");
        comptroller._setTransferPaused(true);
    }
    function test_setSeizePaused() public {
        vm.startPrank(admin);
        comptroller._setSeizePaused(true);
        bool state = comptroller.seizeGuardianPaused();
        assertEq(state,true);
        
        comptroller._setSeizePaused(false);
        state = comptroller.seizeGuardianPaused();
        assertEq(state,false);
        vm.stopPrank();
        
        vm.expectRevert("only pause guardian and admin can pause");
        comptroller._setSeizePaused(true);
    }
    function test_become() public {
        address uni = unitroller.admin();
        testComptroller deploy = new testComptroller();

        vm.startPrank(uni);
        unitroller._setPendingImplementation(address(deploy));
        vm.stopPrank();

        vm.startPrank(uni);
        (bool success,)=address(deploy).call(abi.encodeWithSignature("_become(address)", address(unitroller)));
        assertEq(success,true);
        vm.stopPrank();
    }
    function test_setPendingImplementation_1() public {
        vm.startPrank(admin);
        cEther._setPendingAdmin(user);
        assertEq(cEther.pendingAdmin(),user);
        vm.stopPrank();

        vm.startPrank(user);
        cEther._acceptAdmin();
        assertEq(cEther.admin(),user);
        vm.stopPrank();
    }
    function setComptroller() public { 
        vm.startPrank(admin);
        testComptroller deploy = new testComptroller();
        ComptrollerInterface newComptroller = ComptrollerInterface(deploy);
        
        cEther._setComptroller(newComptroller);
        assertEq(cEther.comptroller(),address(newComptroller));

        vm.expectRevert();
        cEther._setComptroller(ComptrollerInterface(address(1)));
        
        vm.stopPrank();
    }
    function test_setReserveFactor() public {
        vm.startPrank(admin);
        // reserveFactorMaxMantissa => 1e18
        uint Factor=cEther.reserveFactorMantissa();
        
        cEther._setReserveFactor(1e18);
        assertEq(cEther.reserveFactorMantissa(), 1e18);

        cEther._setReserveFactor(Factor + 1);
        assertEq(cEther.reserveFactorMantissa(), Factor+1);
        
        //return errorcode
        uint result = cEther._setReserveFactor(1e18 + 1);
        
        //emit Failure(2, 73, 0) 2 => Comptroller rejection, 73 => SET_RESERVE_FACTOR_VALIDATION
        assertEq(result, 2);
    }
    function test_setreduceReserves() public {
        vm.startPrank(admin);
        
        cEther.accrueInterest();
        uint totalReserves = cEther.totalReserves();
        uint totalCash = cEther.getCash();
        
        cEther._reduceReserves(totalReserves);
        assertEq(cEther.totalReserves(),0);
       
        //return errorcode
        uint result = cEther._reduceReserves(totalReserves + 1);
        //emit Failure(2, 52, 0) 2 => COMPTROLLER_REJECTION, 52 => SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED
        assertEq(result, 2);
        
        //return errorcode
        result = cEther._reduceReserves(totalCash + 1);
        //emit Failure(14, 50, 0) 2 => TOKEN_INSUFFICIENT_ALLOWANCE, 50 => REDEEM_FRESHNESS_CHECK
        assertEq(result, 14);

        vm.stopPrank();
    }
    function test_setInterestRateModel() public {
        vm.startPrank(admin);
        
        testInterestRateModel deploy = new testInterestRateModel();
        InterestRateModel newModel = InterestRateModel(deploy);

        cEther._setInterestRateModel(newModel);
        assertEq(cEther.interestRateModel(),address(newModel));

        vm.expectRevert();
        // require(newInterestRateModel.isInterestRateModel(), "marker method returned false");
        cEther._setInterestRateModel(InterestRateModel(address(0x31337)));
        
        vm.stopPrank();
    }

    function test_cErc20_resignImplementation() public {
        vm.startPrank(admin);
        cDai._resignImplementation();
        vm.stopPrank();

        vm.expectRevert("only the admin may call _resignImplementation");
        cDai._resignImplementation();
    }

    function test_cErc20_becomeImplementation() public {
        vm.startPrank(admin);
        cDai._becomeImplementation(bytes("test"));
        vm.stopPrank();

        vm.expectRevert("only the admin may call _becomeImplementation");
        cDai._becomeImplementation(bytes("test"));
    }

    function test_cErc20_setImplementation() public {
        vm.startPrank(admin);
        cDai._setImplementation(address(0x31337),false,bytes("test"));
        assertEq(cDai.implementation(),address(0x31337));

        cDai._setImplementation(address(0x4567),true,bytes("test"));
        assertEq(cDai.implementation(),address(0x4567));
        vm.stopPrank();

        vm.expectRevert("CErc20Delegator::_setImplementation: Caller must be admin");
        cDai._setImplementation(address(0x4567),true,bytes("test"));
    }
     function test_setPendingImplementation_2() public {
        vm.startPrank(admin);
        unitroller._setPendingImplementation(address(0x31337));
        assertEq(unitroller.pendingComptrollerImplementation(),address(0x31337));
        vm.stopPrank();
        
        //return errorcode
        uint result = unitroller._setPendingImplementation(address(0x31337));
        // emit Failure(: 1, : 15, : 0) 1=> UNAUTHORIZED 15=> SET_PENDING_IMPLEMENTATION_OWNER_CHECK
        assertEq(result,1);
    }
    function test_acceptImplementation() public {
        vm.startPrank(admin);
        unitroller._setPendingImplementation(address(0x31337));

        //return errorcode 
        uint result = unitroller._acceptImplementation();
        //emit Failure(: 1, : 1, : 0) 1=> UNAUTHORIZED 1=> ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK
        assertEq(result,1);
        vm.stopPrank();

        vm.startPrank(address(0x31337));
        unitroller._acceptImplementation();
        assertEq(unitroller.comptrollerImplementation(),address(0x31337));
        vm.stopPrank();
    }
    function test_setPendingAdmin() public{
        vm.startPrank(admin);
        unitroller._setPendingAdmin(user);
        assertEq(unitroller.pendingAdmin(),user);
        vm.stopPrank();

        // return errorcode
        uint result = unitroller._setPendingAdmin(user);
        //emit Failure(: 1, : 14, : 0) 1=> UNAUTHORIZED 14=> SET_PENDING_ADMIN_OWNER_CHECK
        assertEq(result,1);
    }
    function test_acceptAdmin() public {
        vm.startPrank(admin);
        unitroller._setPendingAdmin(user);

        //return errorcode 
        uint result = unitroller._acceptAdmin();
        //emit Failure(: 1, : 0, : 0)1=> UNAUTHORIZED 1=> ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK
        assertEq(result,1);
        vm.stopPrank();

        vm.startPrank(user);
        unitroller._acceptAdmin();
        assertEq(unitroller.admin(),user);
        vm.stopPrank();
    }
    function test_setMintPaused_guardian() public {
        vm.startPrank(pauseGuardian);
        comptroller._setMintPaused(cEther, true);
        bool state = comptroller.mintGuardianPaused(address(cEther));
        assertEq(state,true);
        
        vm.expectRevert("only admin can unpause");
        comptroller._setMintPaused(cEther, false);
        vm.stopPrank();

        vm.expectRevert("only pause guardian and admin can pause");
        comptroller._setMintPaused(cEther, true);
    }
    function test_setBorrowPaused_guardian() public {
        vm.startPrank(pauseGuardian);
        comptroller._setBorrowPaused(cEther, true);
        bool state = comptroller.borrowGuardianPaused(address(cEther));
        assertEq(state,true);
        
        vm.expectRevert("only admin can unpause");
        comptroller._setBorrowPaused(cEther, false);
        vm.stopPrank();
        
        vm.expectRevert("only pause guardian and admin can pause");
        comptroller._setBorrowPaused(cEther, true);
    }
    function test_setTransferPaused_guardian() public {
        vm.startPrank(pauseGuardian);
        comptroller._setTransferPaused(true);
        bool state = comptroller.transferGuardianPaused();
        assertEq(state,true);
        
        vm.expectRevert("only admin can unpause");
        comptroller._setTransferPaused(false);
        vm.stopPrank();
        
        vm.expectRevert("only pause guardian and admin can pause");
        comptroller._setTransferPaused(true);
    }
    function test_setSeizePaused_guardian() public {
        vm.startPrank(pauseGuardian);
        comptroller._setSeizePaused(true);
        bool state = comptroller.seizeGuardianPaused();
        assertEq(state,true);
        
        vm.expectRevert("only admin can unpause");
        comptroller._setSeizePaused(false);
        vm.stopPrank();
        
        vm.expectRevert("only pause guardian and admin can pause");
        comptroller._setSeizePaused(true);
    }
    function test_setMarketBorrowCaps_guardian() public {
        CTokenInterface[] memory cTokens =new CTokenInterface[](1);
        cTokens[0]=cEther;
        uint[] memory newBorrowCaps = new uint[](1);
        newBorrowCaps[0]=1e18;

        uint[] memory wrongBorrowCaps = new uint[](2);
        wrongBorrowCaps[0]=1e18;
        wrongBorrowCaps[1]=2e18;
        
        vm.startPrank(borrowCapGuardian);
        comptroller._setMarketBorrowCaps(cTokens, newBorrowCaps);

        vm.expectRevert("invalid input");
        comptroller._setMarketBorrowCaps(cTokens, wrongBorrowCaps);
        
        vm.stopPrank();

        vm.expectRevert("only admin or borrow cap guardian can set borrow caps");
        comptroller._setMarketBorrowCaps(cTokens, newBorrowCaps);
    }

}