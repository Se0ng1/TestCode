// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "../src/NewComptroller.sol";
import "../src/TestUtils.sol";

/// @notice Example contract that upgrades the Comptroller.
/// This example also goes through the entire governance journey:
/// 1. Create the proposal
/// 2. Vote
/// 3. Queue it to the Timelock
/// 4. Execute the proposal
contract governanceTest is Test, TestUtils {
    NewComptroller newComptroller;

    receive() external payable {}

    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);

        uint256 amount = 400_000 * 1e18;
        deal(address(comp),address(this),amount);

        assertEq(comp.balanceOf(address(this)), amount);

        // Now we delegate all votes to this address.
        comp.delegate(address(this));

        // We increase the block number by 1 so the votes are actionable.
        vm.roll(block.number + 1);
        assertEq(comp.getPriorVotes(address(this), block.number - 1), amount);

        // We create the new singleton Comptroller.
        newComptroller = new NewComptroller();
    }

    /// @notice This test function goes through the complete governance model of Compound.
    /// It ends up upgrading the comptroller singleton.
    function testUpgradeComptroller() public {
        // 1. We CREATE and send the PROPOSAL.
        uint256 proposalId = propose();

        // We increase the block number by the voting delay.
        uint256 votingDelay = gBravo.votingDelay(); // 13140 blocks
        vm.roll(block.number + votingDelay + 1);

        // 2. We VOTE in favor of our proposal.
        gBravo.castVote(proposalId, 1); // 0=against, 1=for, 2=abstain

        // We increase the block number so it gets to the voting end.
        uint256 votingPeriod = gBravo.votingPeriod(); // 19710 blocks
        vm.roll(block.number + votingPeriod);

        // 3. We QUEUE the transaction to the timelock.
        gBravo.queue(proposalId);

        // We increase the timestamp number by the timelock delay.
        uint256 timelockDelay = timelock.delay();

        vm.warp(block.timestamp + timelockDelay);

        // 4. We EXECUTE the PROPOSAL.
        gBravo.execute(proposalId);

        // We accept the implementation.
        newComptroller.acceptImplementation(address(comptroller));

        // We check that the comptroller has been upgraded.
        (bool success, bytes memory data) =
            address(comptroller).staticcall(abi.encodeWithSignature("testImplementation()"));
        require(success);
        string memory result = abi.decode(data, (string));
        assertEq(result, "Hi, we are deepHigh");
    }

    function propose() internal returns (uint256) {
        address[] memory targets = new address[](1);
        targets[0] = address(comptroller);

        uint256[] memory values = new uint[](1);
        values[0] = 0;

        string[] memory signatures = new string[](1);
        signatures[0] = "";

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("_setPendingImplementation(address)", address(newComptroller));

        string memory description = "Upgrades the Comptroller";

        uint256 proposalId = gBravo.propose(targets, values, signatures, calldatas, description);
        require(proposalId > 0, "Proposal failed");
        return proposalId;
    }
}