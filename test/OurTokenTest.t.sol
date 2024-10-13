// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {OurToken} from "src/OurToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";


contract OurTokenTest is Test, ZkSyncChainChecker {
    OurToken public ourToken;
    DeployOurToken public deployer;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant BOB_STARTING_BALANCE = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        if (!isZkSyncChain()) {
            ourToken = deployer.run();
        } else {
            ourToken = new OurToken(INITIAL_SUPPLY);
            ourToken.transfer(msg.sender, INITIAL_SUPPLY);
        }

        vm.prank(msg.sender);
        ourToken.transfer(bob, BOB_STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(BOB_STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000; // it is not the same with 1000 ether

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), BOB_STARTING_BALANCE - transferAmount);
    }

    // Test transfers between accounts
    function testTransfer() public {
        // Mint some tokens to user1 for the test
        vm.prank(msg.sender);
        ourToken.transfer(bob, 1000);

        // Transfer tokens from user1 to user2
        vm.prank(bob);
        bool success = ourToken.transfer(alice, 500);

        // Check the balances
        assertTrue(success);
        assertEq(ourToken.balanceOf(alice), 500);
    }

    // Test for insufficient balance transfer
    function testTransferFailsWhenInsufficientBalance() public {
        // Try to transfer more tokens than user1 has
        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(alice, 1000 ether);
    }

    function testTransferEventEmitted() public {
        // Mint some tokens to user1 for the test
        vm.prank(msg.sender);
        ourToken.transfer(bob, 1000);

        // Expect a Transfer event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Transfer(bob, alice, 500);

        // Transfer tokens from user1 to user2
        vm.prank(bob);
        ourToken.transfer( alice, 500);
    }

    
}
