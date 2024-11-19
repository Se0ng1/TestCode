// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "../src/TestUtils.sol";
import "../src/interfaces/Exponential.sol";

/// @notice Example contract that calculates the account liquidity.
contract claimCompTest is Test, TestUtils, Exponential{
    uint check_supply;
    uint check_borrow;
    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        deal(address(dai),address(this), 10000 * 1e18);
        dai.approve(address(cDai),10000 * 1e18);
    }
    function test_checkCompspeed() public{
        //check Compspeed
        address[] memory cTokens = new address[](20);
        cTokens = comptroller.getAllMarkets();
        for(uint i=0; i<20; i++){
            uint borrowSpeed = comptroller.compSupplySpeeds(cTokens[i]);
            uint supplySpeed = comptroller.compBorrowSpeeds(cTokens[i]);
            
            if(supplySpeed > 0){
                console.log("supply: ",cTokens[i]);
                check_supply++;
            }
            if(borrowSpeed > 0){
                console.log("borrow: ",cTokens[i]);
                check_borrow++;
            }
        }
        assert(check_borrow > 0 && check_supply > 0);
    }
    function test_calcAccruedComp() public {
        //-------------------------------setting----------------------------//
        CTokenInterface[] memory CTokens = new CTokenInterface[](1);
        CTokens[0]=cEther;

        uint[] memory supplySpeeds = new uint[](1);
        supplySpeeds[0] = 2e18;
        uint[] memory borrowSpeeds = new uint[](1);
        borrowSpeeds[0] = 2e18;

        //current speed 0 = > set speed 1e18
        vm.startPrank(admin);
        comptroller._setCompSpeeds(CTokens, supplySpeeds, borrowSpeeds);
        assertEq(comptroller.compBorrowSpeeds(address(cEther)),2e18);
        assertEq(comptroller.compSupplySpeeds(address(cEther)),2e18);
        vm.stopPrank();
        //-------------------------------COMP accrued [mint] ----------------------------//
        
        cEther.mint{value : 1e18}();
        vm.roll(block.number + 1);
        uint supplierIndex = comptroller.compSupplierIndex(address(cEther), address(this));
        uint supplierTokens = cEther.balanceOf(address(this));
        
        cEther.mint{value : 1e18}();
        (uint supplyIndex,) = comptroller.compSupplyState(address(cEther));
 
        Double memory deltaIndex = Double({mantissa: sub_(supplyIndex, supplierIndex)});

        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        assertEq(comptroller.compAccrued(address(this)),supplierDelta);

        //-------------------------------COMP accrued [borrow] ----------------------------//
        
        cDai.mint(10000 * 1e18);
        cEther.borrow(0.5e18);
        uint borrowerIndex = comptroller.compBorrowerIndex(address(cEther), address(this));
        uint borrowerTokens = cEther.balanceOf(address(this));
        vm.roll(block.number + 1);
        cEther.borrow(0.5e18);
        (uint borrowIndex, )=comptroller.compBorrowState(address(cEther));

        deltaIndex = Double({mantissa: sub_(borrowIndex, borrowerIndex)});
        
        uint marketIndex = cEther.borrowIndex();
        uint borrowerAmount = div_(cEther.borrowBalanceCurrent(address(this)), marketIndex);

        uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
        uint borrowerAccrued = add_(comptroller.compAccrued(address(this)), borrowerDelta);
        
        assertEq(comptroller.compAccrued(address(this)),borrowerAccrued);
    }
    receive() external payable{}


}