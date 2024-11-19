// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "../src/TestUtils.sol";

/// @notice Example contract that calculates the account liquidity.
contract cETHTest is Test, TestUtils {
    address user =address(0x1234);
    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
    }
    function getExchangeRate() internal returns (uint) {
        // exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply.
        uint totalCash = cEther.getCash();
        assertEq(totalCash, address(cEther).balance);

        uint totalBorrows = cEther.totalBorrowsCurrent();
        assert(totalBorrows > 0);

        uint totalReserves = cEther.totalReserves();
        assert(totalReserves > 0);

        uint totalSupply = cEther.totalSupply();
        assert(totalSupply > 0);

        uint exchangeRate = 1e18 * (totalCash + totalBorrows - totalReserves) / totalSupply;
        return exchangeRate;
    }
    function test_mint() public {
        cEther.mint{value: 1e18}();

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens);

        (, uint collateralFactorMantissa,) = comptroller.markets(address(cEther));

        (, uint liquidity,) = comptroller.getAccountLiquidity(address(this));
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(cEther));

        uint expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;

        assertEq(liquidity, expectedLiquidity);
    }
    function test_borrow() public {
        assertEq(dai.balanceOf(address(this)), 0);
        cEther.mint{value: 1e18}();

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens); // <- we enter here

        // Checks
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(cEther));

        uint borrowAmount = 500 * 1e18; // 500 dai
        cDai.borrow(borrowAmount);

        assertEq(dai.balanceOf(address(this)), borrowAmount);
    }
    function test_repay() public {
        cEther.mint{value: 1e18}();

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens); // <- we enter here

        uint borrowAmount = 500 * 1e18; // 500 dai
        cDai.borrow(borrowAmount);

        dai.approve(address(cDai), borrowAmount);
        cDai.repayBorrow(borrowAmount);

        assertEq(dai.balanceOf(address(this)), 0);
    }
    function test_repayBorrowBehalf() public {
        vm.deal(user, 1e18);
        vm.startPrank(user);
        //mint
        cEther.mint{value: 1e18}();

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens);
        
        //cDai borrow => 1 ether
        cDai.borrow(1e18);
        vm.stopPrank();

        vm.roll(block.number + 3);

        //repayAmountBehalf
        deal(address(dai),address(this), 2e18);
        uint amount = cDai.borrowBalanceCurrent(user);
        dai.approve(address(cDai),amount);
        cDai.repayBorrowBehalf(user,amount);
        
        amount = cDai.borrowBalanceCurrent(user);
        assertEq(amount,0);
        
    }

    /// @notice Supplies Eth to Compound, checks balances, accrues interests, and redeems.
    function test_redeem() public {
        uint initialEthBalance = address(this).balance;
        cEther.mint{value: 1e18}();

        uint exchangeRate = getExchangeRate();
        uint test = cEther.exchangeRateCurrent();
        assertEq(exchangeRate, test);

        uint cEtherBalance = cEther.balanceOf(address(this));

        // We get the amount of cEther that we should have.
        uint mintTokens = 1e18 * 1e18 / exchangeRate;
        assertEq(cEtherBalance, mintTokens);

        vm.roll(block.number + 1);

        require(cEther.redeem(cEther.balanceOf(address(this))) == 0, "redeem failed");
        assertEq(cEther.balanceOf(address(this)), 0);

        //should have more eth with 1 block of interests.
        assert(address(this).balance > initialEthBalance);
    }
    function test_redeemUnderlying() public{
        cEther.mint{value : 1e18}();
        uint bf = cEther.balanceOf(address(this));
        vm.roll(block.number + 1);

        uint amount = address(this).balance;
        cEther.redeemUnderlying(1e18);
        assertEq(address(this).balance - 1e18, amount);
        //calculation underlying amount
        uint exchangeRate = cEther.exchangeRateCurrent();
        uint calc = 1e18 * 1e18/exchangeRate;
        uint af = cEther.balanceOf(address(this));
        
        assertEq(af, bf-calc);
    }
    function test_transfer() public {
        cEther.mint{value: 1e18}();
        uint cETH = cEther.balanceOf(address(this));

        cEther.transfer(user,cEther.balanceOf(address(this)));

        assertEq(cETH,cEther.balanceOf(user));
    }
    function test_liquidate() public {
        uint setAmount = 10 * 1e18;
        vm.deal(user, setAmount);
        vm.startPrank(user);
        cEther.mint{value : setAmount}();

        //enter market
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens);
        uint borrowAmount = 100 * 1e18;
        cDai.borrow(borrowAmount);
        vm.stopPrank();
        
        vm.roll(block.number + 1);
        setAmount = 10000 * 1e18;
        deal(address(dai),address(this),setAmount);
        dai.approve(address(cDai),setAmount);

        // Set Ether price 2409694773110000000000 -> 9694773110000000000
        vm.mockCall(
            address(oracle),
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(cEther)),
            abi.encode(9694773110000000000)
        );
        //check MAX repayAmount
        uint factor = comptroller.closeFactorMantissa();
        uint borrowed = cDai.borrowBalanceCurrent(user);
        uint amount = (borrowed * factor) / 1e18;
        
        vm.expectRevert();
        cDai.liquidateBorrow(user, amount+1, cEther);
        
        //borrower collateral totalToken >= seizeToken Amount
        cDai.liquidateBorrow(user,amount,cEther);
    }
    function test_enterMarket() public {
        address[] memory markets = new address[](1);
        markets[0] = address(cEther);
        comptroller.enterMarkets(markets);

        // Checks
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(cEther));
    }
    function test_exitMarket() public {
        address[] memory markets = new address[](1);
        markets[0] = address(cEther);
        comptroller.enterMarkets(markets);

        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn.length, 1);

        comptroller.exitMarket(address(cEther));
        assetsIn = comptroller.getAssetsIn(address(this));
        //check delete asset
        assertEq(assetsIn.length, 0);
    }
    receive() payable external{}

}
