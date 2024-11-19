// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/testFile.sol";

contract guardianTest is Test, TestUtils {
    address payable user =payable(address(0x1234));
    address pauseGuardian;
    address borrowCapGuardian;
    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        pauseGuardian = comptroller.pauseGuardian();
        borrowCapGuardian = comptroller.borrowCapGuardian();
    }

    function test_setMintPaused() public {
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
    function test_setBorrowPaused() public {
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
    function test_setTransferPaused() public {
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
    function test_setSeizePaused() public {
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
    function test_setMarketBorrowCaps() public {
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