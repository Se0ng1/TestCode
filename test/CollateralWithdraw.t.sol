// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/interfaces/Exponential.sol";
import "../src/TestFile.sol";
contract CollateralWithdrawTest is Test, TestUtils, Exponential, tools{
    address lender = address(this);
    uint supplyAmount = 10 * 1e18;
    
    
    function setUp() public{
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        vm.deal(lender,supplyAmount);
        cEther.mint{value : supplyAmount}();

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens); 
    }

    function test_withdraw_simpleToken() public {
        uint exchangeRate = cEther.exchangeRateCurrent();
        uint cEtherBalance = cEther.balanceOf(address(this));

        // We get the amount of cEther that we should have.
        uint mintTokens = supplyAmount * 1e18 / exchangeRate;
        assertEq(cEtherBalance, mintTokens);

        vm.roll(block.number + 1);

        require(cEther.redeem(cEther.balanceOf(address(this))) == 0, "redeem failed");
        assertEq(cEther.balanceOf(address(this)), 0);
        
        //should have more eth with 1 block of interests.
        assertGt(address(this).balance , supplyAmount);
    }
    function test_withdraw_simpleUnderlying() public{
        uint beforeAmount = cEther.balanceOf(address(this));
        vm.roll(block.number + 1);

        cEther.redeemUnderlying(supplyAmount);
        assertEq(address(this).balance,supplyAmount);
        
        //calculation underlying amount
        uint exchangeRate = cEther.exchangeRateCurrent();
        uint calc = supplyAmount * 1e18/exchangeRate;
        uint afterAmount = cEther.balanceOf(address(this));
        assertEq(afterAmount, beforeAmount-calc);
    }
    function test_withdraw_checkMarket() public{
        /*
        withdraw call Sequence redeem/redeemUnderlying => redeemInternal/redeemUnderlying => redeemFresh => redeemAllowed
        */
        vm.startPrank(address(Not_registered_cToken));
        uint Errorcode =comptroller.redeemAllowed(address(Not_registered_cToken),lender,supplyAmount);
        vm.stopPrank();
        // Errorcode = MARKET_NOT_LISTED
        assertEq(Errorcode,9);

        vm.startPrank(address(cDai));
        Errorcode =comptroller.redeemAllowed(address(cDai),lender,supplyAmount);
        vm.stopPrank();
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
    function test_withdraw_checkLTV() public {
        uint amount = cEther.balanceOf(lender);

        //over LTV
        (,,uint shortfall)=comptroller.getHypotheticalAccountLiquidity(lender,address(cEther),amount+1,0);
        console.log(shortfall);

        assertGt(shortfall,0);

        //return Errorcode
        uint Errorcode = cEther.redeem(cEther.balanceOf(lender)+1);
        //Errorcode =>INSUFFICIENT_SHORTFALL
        assertEq(Errorcode, 3);
        
        //return Errorcode
        Errorcode = cEther.redeemUnderlying(supplyAmount + 1e18);
        //Errorcode =>INSUFFICIENT_SHORTFALL
        assertEq(Errorcode,3);
    }
    function test_withdraw_checkOut() public {
        assertEq(cEther.borrowBalanceCurrent(lender),0);
    
        cDai.borrow(1e18);
        uint Errorcode=comptroller.exitMarket(address(cEther));
        //Errorcode => REJECTION
        assertEq(Errorcode, 14);
    }
    function test_withdraw_checkAccrueBlock() public {
        cEther.redeem(cEther.balanceOf(lender));
        assertEq(cEther.accrualBlockNumber(),block.number);
    }
    function test_withdraw_checkAmount() public {
        deal(address(cEther),lender,10000*1e18);

        uint exchangeRate = cEther.exchangeRateCurrent();
        uint totalBalance = address(cEther).balance;
        uint calcBalance =totalBalance/(exchangeRate /1e18);
        
        //return Errorcode
        uint Errorcode=cEther.redeem(calcBalance + 1);
        //Errorcode => REJECTION
        assertEq(Errorcode,14);
        
        //return Errorcode
        Errorcode = cEther.redeemUnderlying(totalBalance+1);
        //Errorcode => REJECTION
        assertEq(Errorcode,14);
    }


    receive() external payable{}

}