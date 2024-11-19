// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/testFile.sol";

/// @notice Example contract that calculates the account liquidity.
contract admin_UnitrollerTest is Test, TestUtils {
    address payable user =payable(address(0x1234));
    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
    }
    function test_setPendingImplementation() public {
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
}