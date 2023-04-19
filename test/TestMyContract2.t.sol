// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MyContract2} from "../src/MyContract2.sol";

contract TestMyContract2 is Test {
    MyContract2 instance;
    address user1;
    address user2;

    event Receive(address from, uint256 amount);
    event Send(address to, uint256 amount);

    function setUp() public {
        //  Set user1, user2
        user1 = address(1);
        user2 = address(2);
        // (optional) label user1 as bob, user2 as alice
        vm.label(user1, "bob");
        vm.label(user2, "alice");
        //  Create a new instance of MyContract2
        instance = new MyContract2(user1, user2);
    }

    function testConstructor() public {
        // Assert instance.user1() is user1
        // Assert instance.user2() is user2
        assertEq(instance.user1(), user1);
        assertEq(instance.user2(), user2);
    }

    function testReceiveEther() public {
        // expect event
        vm.expectEmit(false, false, false, true, address(instance));
        // expected specific log
        emit Receive(user1, 1 ether);
        // pretending you are user1
        vm.startPrank(user1);
        // let user1 have 1 ether
        vm.deal(user1, 1 ether);
        // send 1 ether to instance
        (bool success,) = address(instance).call{value: 1 ether}(""); // send 1 ether to instance
        require(success);
        // Assert instance has 1 ether in balance
        assertEq(address(instance).balance, 1 ether);
        // stop pretending
        vm.stopPrank();
    }

    function send(address to, uint256 amount) external payable {
        require(msg.sender == user1 || msg.sender == user2, "only user1 or user2 can send");
        require(address(this).balance >= amount, "insufficient balance");

        (bool success,) = to.call{value: amount}("");
        require(success, "transfer failed");
        emit Send(to, amount);
    }

    function testSend(address _addr, address _to, uint256 _amount, uint256 _balance) public {
        vm.deal(address(instance), _balance); // contract's balance is _balance
        vm.startPrank(_addr); // pretending as _addr
        if (_addr != user1 && _addr != user2) {
            // msg.sender is not user1 nor user2
            vm.expectRevert("only user1 or user2 can send");
            instance.send(_to, _amount);
        } else if (_balance < _amount) {
            // contract balance is < _amount
            vm.expectRevert("insufficient balance");
            instance.send(_to, _amount);
        } else {
            vm.expectEmit(false, false, false, true, address(instance)); // expect event
            emit Send(_to, _amount);
            instance.send(_to, _amount);
            assertEq(_to.balance, _amount); // check if _addr.balance == _amount
        }
        vm.stopPrank();
    }
}
