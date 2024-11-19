// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "../src/TestUtils.sol";

/// @notice Example contract that calculates the account liquidity.
contract cErc20test is Test, TestUtils {
    address user =address(0x1234);
    uint mintAmount = 20 * 1e18;
    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        uint setAmount = 10000 * 1e18;
        deal(address(dai),address(this),setAmount);
        dai.approve(address(cDai), setAmount);
    }
    function getExchangeRate() internal returns (uint) {
        // exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply.
        uint totalCash = cDai.getCash();
        assertEq(totalCash, dai.balanceOf(address(cDai)));

        uint totalBorrows = cDai.totalBorrowsCurrent();
        assert(totalBorrows > 0);

        uint totalReserves = cDai.totalReserves();
        assert(totalReserves > 0);

        uint totalSupply = cDai.totalSupply();
        assert(totalSupply > 0);

        uint exchangeRate = 1e18 * (totalCash + totalBorrows - totalReserves) / totalSupply;
        return exchangeRate;
    }
    function test_mint() public {
        cDai.mint(1e18);
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDai);
        comptroller.enterMarkets(cTokens);

        (, uint collateralFactorMantissa,) = comptroller.markets(address(cDai));

        (, uint liquidity,) = comptroller.getAccountLiquidity(address(this));
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(cDai));

        uint expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;

        assertEq(liquidity, expectedLiquidity);
    }
    function test_borrow() public {
        cDai.mint(mintAmount);

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDai);
        comptroller.enterMarkets(cTokens); // <- we enter here

        // Checks
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(cDai));
        
        cLINK.borrow(1e18);

        assertEq(link.balanceOf(address(this)), 1e18);
    }
    function test_repay() public {
        cDai.mint(mintAmount);
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDai);
        comptroller.enterMarkets(cTokens); // <- we enter here

        cLINK.borrow(1e18);
        assertEq(link.balanceOf(address(this)),1e18);

        vm.roll(block.number + 5);
        
        // totalborrows => borrow amount + interest 
        uint amount =cLINK.borrowBalanceCurrent(address(this));

        deal(address(link),address(this),amount);
        link.approve(address(cLINK), amount);
        
        //repay amount
        cLINK.repayBorrow(amount);

        assertEq(link.balanceOf(address(this)), 0);
    }
    function test_repayBorrowBehalf() public {
        deal(address(dai),user,mintAmount);
        
        vm.startPrank(user);
        dai.approve(address(cDai), mintAmount);

        //mint
        cDai.mint(mintAmount);
        //enter market [cETH]
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDai);
        comptroller.enterMarkets(cTokens);

        //borrow 1 ETH
        cLINK.borrow(1e18);
        vm.stopPrank();

        vm.roll(block.number + 3);
        
        //user totalborrows => borrow amount + interest
        uint amount = cLINK.borrowBalanceCurrent(user);
        deal(address(link),address(this),amount);
        link.approve(address(cLINK), amount);
        
        //repay user's totalBorrow
        cLINK.repayBorrowBehalf(user,amount);

        //after repay => must be 0
        amount = cEther.borrowBalanceCurrent(user);
        assertEq(amount,0);
    }

    // @notice Supplies Eth to Compound, checks balances, accrues interests, and redeems.
    function test_redeem() public {
        uint initialBalance = dai.balanceOf(address(this));
        cDai.mint(mintAmount);
        //test equal exchangeRate function
        uint exchangeRate = getExchangeRate();
        uint test = cDai.exchangeRateCurrent();
        assertEq(exchangeRate, test);

        uint daiAmount = cDai.balanceOf(address(this));
        
        //calc mint amount
        uint mintTokens = mintAmount * 1e18 / exchangeRate;
        assertEq(daiAmount, mintTokens);

        vm.roll(block.number + 5);

        cDai.redeem(cDai.balanceOf(address(this)));
        assertEq(cDai.balanceOf(address(this)), 0);

        //should have more dai with 5 block of interests.
        assert(dai.balanceOf(address(this)) > initialBalance);
    }
    function test_redeemUnderlying() public{
        cDai.mint(mintAmount);
        uint bf = cDai.balanceOf(address(this));
        uint amount = dai.balanceOf(address(this));
        vm.roll(block.number + 5);
        
        //redeem => total dai + 1e18
        cDai.redeemUnderlying(1 ether);
        assertEq(dai.balanceOf(address(this))- 1 ether,amount);
        
        //calc cDai token amount
        uint exchangeRate = cDai.exchangeRateCurrent();
        uint calc = 1e18 * 1e18/exchangeRate;
        uint af = cDai.balanceOf(address(this));
        assertEq(af, bf-calc);
    }
    function test_transfer() public {
        cDai.mint(mintAmount);
        uint amount = cDai.balanceOf(address(this));

        cDai.transfer(user,cDai.balanceOf(address(this)));

        assertEq(amount,cDai.balanceOf(user));
    }

    function test_liquidate() public {
        deal(address(dai), user, mintAmount);
        vm.startPrank(user);
        dai.approve(address(cDai), mintAmount);
        cDai.mint(mintAmount);

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDai);
        comptroller.enterMarkets(cTokens);

        cLINK.borrow(1e18);
        vm.stopPrank();

        //set Dai price  999780000000000000 -> 99780000000000000
        vm.roll(block.number + 5);
        vm.mockCall(
            address(oracle),
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(cDai)),
            abi.encode(99780000000000000) 
        );
        //check MAX repayAmount
        uint factor = comptroller.closeFactorMantissa();
        uint borrowed = cLINK.borrowBalanceCurrent(user);
        uint amount = (borrowed * factor) / 1e18;
        
        deal(address(link), address(this), 1e18); 
        link.approve(address(cLINK), 1e18); 
        
        vm.expectRevert();
        //repayAmount =< maxRepay(closeFactor * totalBorrow)
        cLINK.liquidateBorrow(user, amount+1, cDai); 

        //borrower collateral totalToken >= seizeToken Amount
        cLINK.liquidateBorrow(user, 0.17 ether, cDai); 
    }
    function test_addReserves() public {
        cDai.accrueInterest();
        
        uint amount = 1000 * 1e18;
        uint bf = cDai.totalReserves();
        
        cDai._addReserves(amount);
        assertEq(cDai.totalReserves() - amount , bf);
    }
    function test_enterMarket() public {
        address[] memory markets = new address[](1);
        markets[0] = address(cDai);
        comptroller.enterMarkets(markets);

        // Checks
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(cDai));
    }
    function test_exitMarket() public {
        address[] memory markets = new address[](1);
        markets[0] = address(cDai);
        comptroller.enterMarkets(markets);

        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn.length, 1);

        comptroller.exitMarket(address(cDai));
        assetsIn = comptroller.getAssetsIn(address(this));
        //check delete asset
        assertEq(assetsIn.length, 0);
    }

    receive() payable external{}

}

