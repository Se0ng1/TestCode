// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/interfaces/Exponential.sol";
import "../src/TestFile.sol";
import "../src/interfaces/TokenErrorReporter.sol";

contract RepaymentTest is Test, TestUtils, Exponential, tools{
    address borrower = address(this);
    address lender = makeAddr("lender");
    uint borrowAmount = 10000 * 1e18;
    uint supplyAmount = 10* 1e18;
    
    function setUp() public{
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        cEther.mint{value : supplyAmount}();

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens); 
        cDai.borrow(borrowAmount);
        dai.approve(address(cDai),type(uint).max);

        //------------------------------------------- //
        deal(address(dai),lender,borrowAmount * 2);
        vm.startPrank(lender);
        dai.approve(address(cDai),type(uint).max);
        cTokens[0] = address(cDai);
        comptroller.enterMarkets(cTokens);
        vm.stopPrank();
    }
     function test_repay_simpleBehalf() public {
        vm.roll(block.number + 3);
        uint beforeBalance = dai.balanceOf(lender);
        
        vm.startPrank(lender);
        uint repayAmount=cDai.borrowBalanceCurrent(borrower);
        //borrowAmount + 3 block interest
        cDai.repayBorrowBehalf(borrower,repayAmount);
        vm.stopPrank();

        uint afterBalance = dai.balanceOf(lender);
        assertEq(afterBalance,beforeBalance -repayAmount);
    }
    function test_repay_simple() public {
        vm.roll(block.number + 3);
        uint repayAmount=cDai.borrowBalanceCurrent(borrower);
        deal(address(dai),borrower, repayAmount); 

        cDai.repayBorrow(repayAmount);
        
        assertEq(cDai.balanceOf(borrower),0);
    }

    function test_repay_checkMarket() public{
        /*
        repayBorrow call Sequence repayBorrow => repayBorrowInternal => repayBorrowFresh => repayBorrowAllowed
        */
        vm.startPrank(address(Not_registered_cToken));
        uint Errorcode =comptroller.repayBorrowAllowed(address(Not_registered_cToken),borrower,borrower,borrowAmount);
        vm.stopPrank();
        // Errorcode = MARKET_NOT_LISTED
        assertEq(Errorcode,9);

        vm.startPrank(address(cDai));
        Errorcode =comptroller.repayBorrowAllowed(address(cDai),borrower,borrower,borrowAmount);
        vm.stopPrank();
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
    function test_repay_checkAccrueBlock() public{
        cDai.repayBorrow(borrowAmount);
        assertEq(cDai.accrualBlockNumber(),block.number);
    }
    function test_repay_checkOut() public{
        //return Errorcode
        uint Errorcode = comptroller.exitMarket(address(cDai));
        // Errorcode => NONZERO_BORROW_BALANCE
        assertEq(Errorcode,12);
        
        //repay BorrowAmount
        cDai.repayBorrow(borrowAmount);
        Errorcode = comptroller.exitMarket(address(cDai));
        //Errorcode => NO.Error
        assertEq(Errorcode,0);
    }
    function test_repay_checkOut2() public{
        //return Errorcode
        uint Errorcode = comptroller.exitMarket(address(cDai));
        // Errorcode => NONZERO_BORROW_BALANCE
        assertEq(Errorcode,12);
        
        //repay BorrowAmount
        vm.startPrank(lender);
        cDai.repayBorrowBehalf(borrower, borrowAmount);
        vm.stopPrank();
        
        Errorcode = comptroller.exitMarket(address(cDai));
        //Errorcode => NO.Error
        assertEq(Errorcode,0);
    }
    
    function test_repay_checkAmount() public {
        deal(address(dai),borrower,borrowAmount * 2);
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        cDai.repayBorrow(borrowAmount + 1);

        vm.startPrank(lender);
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        cDai.repayBorrowBehalf(borrower, borrowAmount+1);
        vm.stopPrank();
    }
}