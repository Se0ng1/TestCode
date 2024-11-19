// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/interfaces/Exponential.sol";
import "../src/TestFile.sol";
import "../src/interfaces/TokenErrorReporter.sol";

contract LiquidationTest is Test, TestUtils, Exponential, tools{
    address lender = address(this);
    address borrower = makeAddr("borrower");
    uint borrowAmount = 10000 * 1e18;
    uint supplyAmount = 10* 1e18;
    
    function setUp() public{
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        vm.deal(borrower, supplyAmount);
        
        vm.startPrank(borrower);
        cEther.mint{value : supplyAmount}();

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens); 
        
        cDai.borrow(borrowAmount);
        dai.approve(address(cDai),type(uint).max);
        vm.stopPrank();

        deal(address(dai),lender,borrowAmount*2);
    }
    function test_liquidate_checkMarket() public {
        pass_accrueInterest();
        bytes memory Errorcode = abi.encodeWithSignature("LiquidateComptrollerRejection(uint256)", 9);
        //Errorcode => MARKET_NOT_LISTED
        vm.expectRevert(Errorcode);
        cDai.liquidateBorrow(borrower, 1, Not_registered_cToken);
    }
    function test_liquidate_checkLTV() public{
        bytes memory Errorcode = abi.encodeWithSignature("LiquidateComptrollerRejection(uint256)", 3);
        //Errorcode => INSUFFICIENT_SHORTFALL
        vm.expectRevert(Errorcode);
        cDai.liquidateBorrow(borrower, 1, cEther);
    }

}