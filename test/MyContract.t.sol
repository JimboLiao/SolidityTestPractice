// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import { MyContract } from "../src/MyContract.sol";

contract MyContractTest is Test {

  MyContract instance;
  address user1;
  address user2;

  event Receive(address from, uint256 amount);

  function setUp() public {   
    //  Set user1, user2 
    user1 = address(1);
    user2 = address(2);
    // (optional) label user1 as bob, user2 as alice
    vm.label(user1,"bob");
    vm.label(user2,"alice");
    //  Create a new instance of MyContract
    instance = new MyContract(user1, user2);
  }

  function testConstructor() public {
    // Assert instance.user1() is user1
    // Assert instance.user2() is user2
    assertEq(instance.user1(), user1);
    assertEq(instance.user2(), user2);
  }

  function testReceiveEther() public {
    // expect event
    vm.expectEmit(false,false,false,true,address(instance));
    // expected specific log
    emit Receive(user1, 1 ether);
    // pretending you are user1
    vm.startPrank(user1);
    // let user1 have 1 ether
    vm.deal(user1, 1 ether);
    // send 1 ether to instance
    (bool success, ) = address(instance).call{value: 1 ether}(""); // send 1 ether to instance
    require(success);
    // Assert instance has 1 ether in balance
    assertEq(address(instance).balance, 1 ether);
    // stop pretending
    vm.stopPrank();
  }
}