// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/TestFile.sol";

/// @notice Example contract that calculates the account liquidity.
contract admin_ComptrollerTest is Test, TestUtils {
    address payable user =payable(address(0x1234));
    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
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
    function test_grantComp() public {
        vm.startPrank(admin);
        uint amount =comp.balanceOf(address(comptroller));
        comptroller._grantComp(user, amount);
        assertEq(comp.balanceOf(user),amount);

        vm.expectRevert("insufficient comp for grant");
        comptroller._grantComp(user, amount+1);
        vm.stopPrank();

        vm.expectRevert("only admin can grant comp");
        comptroller._grantComp(user, amount);
    }
    function test_setCompSpeedss() public{
        CTokenInterface[] memory CTokens = new CTokenInterface[](1);
        CTokens[0]=cEther;

        CTokenInterface[] memory wrongCTokens = new CTokenInterface[](1);
        wrongCTokens[0]= CTokenInterface(user);

        uint[] memory supplySpeeds = new uint[](1);
        supplySpeeds[0] = 1e18;
        uint[] memory borrowSpeeds = new uint[](1);
        borrowSpeeds[0] = 2e18;

        uint[] memory wrongsupplySpeeds = new uint[](2);
        wrongsupplySpeeds[0] = 1e18;
        wrongsupplySpeeds[1] = 2e18;

        vm.startPrank(admin);
        comptroller._setCompSpeeds(CTokens, supplySpeeds, borrowSpeeds);
        assertEq(comptroller.compBorrowSpeeds(address(cEther)),2e18);
        assertEq(comptroller.compSupplySpeeds(address(cEther)),1e18);

        vm.expectRevert("Comptroller::_setCompSpeeds invalid input");
        comptroller._setCompSpeeds(CTokens, wrongsupplySpeeds, borrowSpeeds);
        
        vm.expectRevert("comp market is not listed");
        comptroller._setCompSpeeds(wrongCTokens, supplySpeeds, borrowSpeeds);

        vm.stopPrank();
        vm.expectRevert("only admin can set comp speed");
        comptroller._setCompSpeeds(CTokens, supplySpeeds, borrowSpeeds);
    }
    function test_setContributorCompSpeed() public {
        vm.startPrank(admin);
        comptroller._setContributorCompSpeed(user, 31337 * 1e18);
        assertEq(comptroller.compContributorSpeeds(user), 31337 * 1e18);
        vm.stopPrank();

        vm.expectRevert("only admin can set comp speed");
        comptroller._setContributorCompSpeed(user, 31337 * 1e18);
    }

}

