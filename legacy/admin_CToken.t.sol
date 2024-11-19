// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/TestFile.sol";

/// @notice Example contract that calculates the account liquidity.
contract admin_CTokenTest is Test, TestUtils {
    address payable user =payable(address(0x1234));
    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
    }

    function test_setPendingImplementation() public {
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
    function test_CErc20_sweepToken() public {
        assertEq(link.balanceOf(admin), 0);
        deal(address(link),address(cDai), 100 * 1e18);
        
        vm.startPrank(admin);
        
        cDai.sweepToken(link);
        assertEq(link.balanceOf(admin), 100 * 1e18);

        vm.expectRevert("CErc20::sweepToken: can not sweep underlying token");
        cDai.sweepToken(dai);
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
}