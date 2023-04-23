// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "forge-std/Test.sol";

interface BAYC {
    function mintApe(uint numberOfTokens) external payable;
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract TestFork is Test {
    function setUp() public {
        // set ETH_RPC_URL in .env
        
        // source .env
        // forge test --fork-url $ETH_RPC_URL --fork-block-number 12299047 --match-contract TestFork -vvvvv

    }

    function testFork() public {
        assertEq(block.number, 12299047);
    }

    // need at least 8 eth
    // contract address 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
    // 0.08 eth / ape
    // function mintApe(uint numberOfTokens) public payable 
    function testMintApe() public {
        address user1 = address(1);
        vm.deal(user1, 20 ether);
        
        address baycAddr = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        uint256 originalBalance = baycAddr.balance;
        vm.startPrank(user1);
        BAYC(baycAddr).mintApe{value: 1.6 ether}(20); // 20 tokens at most in 1 time
        BAYC(baycAddr).mintApe{value: 1.6 ether}(20);
        BAYC(baycAddr).mintApe{value: 1.6 ether}(20);
        BAYC(baycAddr).mintApe{value: 1.6 ether}(20);
        BAYC(baycAddr).mintApe{value: 1.6 ether}(20);
        vm.stopPrank();

        assertEq(BAYC(baycAddr).balanceOf(user1), 100); // user1's balance is 100
        assertEq((baycAddr.balance - originalBalance), 8 ether); // received 8 ether
    }

    
}


