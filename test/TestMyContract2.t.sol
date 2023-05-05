// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MyContract2} from "../src/MyContract2.sol";
import "forge-std/console.sol";

contract TestMyContract2 is Test {
    MyContract2 instance;
    address user1;
    address user2;

    event Receive(address from, uint256 amount);
    event Send(address to, uint256 amount);

    function setUp() public {
        //  Set user1, user2
        // (optional) label user1 as bob, user2 as alice
        user1 = makeAddr("bob");
        user2 = makeAddr("alice");
        
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

    /*
    function testSendEther(address _addr, address _to, uint256 _amount, uint256 _balance) public {
        vm.deal(address(instance), _balance); // contract's balance is _balance
        vm.startPrank(_addr); // pretending as _addr
        if (_addr != user1 && _addr != user2) {
            // msg.sender is not user1 nor user2
            vm.expectRevert("only user1 or user2 can send");
            instance.sendEther(_to, _amount);
        } else if (_balance < _amount) {
            // contract balance is < _amount
            vm.expectRevert("insufficient balance");
            instance.sendEther(_to, _amount);
        } else {
            vm.expectEmit(false, false, false, true, address(instance)); // expect event
            emit Send(_to, _amount);
            instance.sendEther(_to, _amount);
            assertEq(_to.balance, _amount); // check if _addr.balance == _amount
        }
        vm.stopPrank();
    }
    */

    function testSendEtherNotUsers() public {
        vm.deal(address(instance), 1 ether);
        vm.startPrank(address(3));
        vm.expectRevert("only user1 or user2 can send");
        instance.sendEther(user1, 1 ether);
        vm.stopPrank();
        console.logAddress(user1);
    }

    function testSendEtherNotEnoughBalance() public {
        vm.deal(address(instance), 1 ether);
        vm.startPrank(user1);
        vm.expectRevert("insufficient balance");
        instance.sendEther(user1, 2 ether);
        vm.stopPrank();
    }

    function testSendEther() public {
        vm.deal(address(instance), 1 ether);
        vm.startPrank(user1);
        vm.expectEmit(false, false, false, true, address(instance)); // expect event
        emit Send(user1, 1 ether);
        instance.sendEther(user1, 1 ether);
        assertEq(user1.balance, 1 ether); // check user1's balance
        vm.stopPrank();
    }
}

// deploy and verify by forge create
// https://book.getfoundry.sh/forge/deploying#deploying
// set SEPOLIA_RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY in .env
// $ source .env
// $ forge create --rpc-url $SEPOLIA_RPC_URL --constructor-args 0xa08F892dF32a6c56531cB60e828feaDc4b42D5bb 0x083f1c6b5BA3089c5342639549923b5723a08c12 \
//  --private-key $PRIVATE_KEY \
//  --etherscan-api-key $ETHERSCAN_API_KEY \
//  --verify \
//  src/MyContract2.sol:MyContract2

// tx hash 0xe2e91b1fbb63a5df16a5be8cdde3e2089b606770aae82a386643f06f23a3b168
