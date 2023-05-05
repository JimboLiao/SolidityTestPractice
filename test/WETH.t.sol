// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/WETH.sol";

contract WethTest is Test {
    WETH instance;
    address bob;
    address alice;
    uint256 bobPrivateKey;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Withdraw(address indexed to, uint256 indexed amount);
    event Deposit(address indexed from, uint256 indexed amount);

    function setUp() public {
        instance = new WETH();
        (bob, bobPrivateKey) = makeAddrAndKey("bob");
        alice = makeAddr("alice");
    }

    // test deposit function
    function testDeposit() public {
        vm.deal(bob, 1 ether);
        vm.startPrank(bob);
        // 測項 3: deposit 應該要 emit Deposit event
        vm.expectEmit(true, true, false, true, address(instance));
        emit Deposit(bob, 1 ether);
        instance.deposit{value: 1 ether}();
        vm.stopPrank();

        // 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
        assertEq(instance.balanceOf(bob), 1 ether); // 1 ether = 10**18
        // 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
        assertEq(address(instance).balance, 1 ether);
        assertEq(bob.balance, 0);
        // weth totalSupply should be 1 ether
        assertEq(instance.totalSupply(), 1 ether);
    }

    function testReceive() public {
        vm.deal(bob, 1 ether);
        vm.startPrank(bob);
        // 測項 3: deposit 應該要 emit Deposit event
        vm.expectEmit(true, true, false, true, address(instance));
        emit Deposit(bob, 1 ether);
        (bool success,) = address(instance).call{value: 1 ether}("");
        assertTrue(success);
        vm.stopPrank();

        // 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
        assertEq(instance.balanceOf(bob), 1 ether); // 1 ether = 10**18
        // 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
        assertEq(address(instance).balance, 1 ether);
        assertEq(bob.balance, 0);
        // weth totalSupply should be 1 ether
        assertEq(instance.totalSupply(), 1 ether);
    }

    // test withdraw function
    function testWithdraw(uint256 _amount) public {
        vm.deal(bob, _amount);
        vm.startPrank(bob);
        instance.deposit{value: _amount}();
        assertEq(bob.balance, 0);

        // 測項 6: withdraw 應該要 emit Withdraw event
        vm.expectEmit(true, true, false, true, address(instance));
        emit Withdraw(bob, _amount);
        instance.withdraw(_amount);
        // 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
        assertEq(instance.totalSupply(), 0);
        assertEq(instance.balanceOf(bob), 0);
        // 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
        assertEq(bob.balance, _amount);
        vm.stopPrank();
    }

    // test transfer function
    function testTransfer() public {
        vm.deal(bob, 1 ether);
        vm.startPrank(bob);
        instance.deposit{value: 1 ether}();
        assertEq(instance.balanceOf(bob), 1 ether);
        // expect transfer event
        vm.expectEmit(true, true, false, true, address(instance));
        emit Transfer(bob, alice, 1 ether);
        assertTrue(instance.transfer(alice, 1 ether)); // check the return boolean

        // 測項 7: transfer 應該要將 erc20 token 轉給別人
        assertEq(instance.balanceOf(alice), 1 ether);
        assertEq(instance.balanceOf(bob), 0);
        assertEq(instance.totalSupply(), 1 ether);
        vm.stopPrank();
    }

    // test approve function
    function testApprove() public {
        // expect approval event
        vm.expectEmit(true, true, false, true, address(instance));
        emit Approval(bob, alice, 1 ether);
        vm.prank(bob);
        assertTrue(instance.approve(alice, 1 ether)); // check the return boolean
        // 測項 8: approve 應該要給他人 allowance
        assertEq(instance.allowance(bob, alice), 1 ether);
    }

    // test transferFrom function
    function testTransferFrom() public {
        vm.deal(bob, 1 ether);
        vm.startPrank(bob);
        instance.deposit{value: 1 ether}();
        instance.approve(alice, 1 ether);
        assertEq(instance.allowance(bob, alice), 1 ether);
        vm.stopPrank();

        // 測項 9: transferFrom 應該要可以使用他人的 allowance
        vm.prank(alice);
        assertTrue(instance.transferFrom(bob, alice, 1 ether)); // check the return boolean
        assertEq(instance.balanceOf(alice), 1 ether);
        assertEq(instance.balanceOf(bob), 0);
        assertEq(instance.totalSupply(), 1 ether);
        // 測項 10: transferFrom 後應該要減除用完的 allowance
        assertEq(instance.allowance(bob, alice), 0);
    }

    // test transferFrom when approve type(uint256).max
    function testApproveMaxTransferFrom() public {
        vm.deal(bob, 1 ether);
        vm.startPrank(bob);
        instance.deposit{value: 1 ether}();
        instance.approve(alice, type(uint256).max); // solmate's ERC20 will not decrease the allowance if approved with max value
        assertEq(instance.allowance(bob, alice), type(uint256).max);
        vm.stopPrank();

        vm.prank(alice);
        assertTrue(instance.transferFrom(bob, alice, 1 ether)); // check the return boolean
        assertEq(instance.balanceOf(alice), 1 ether);
        assertEq(instance.balanceOf(bob), 0);
        assertEq(instance.totalSupply(), 1 ether);
        // expect the allowance remains the same
        assertEq(instance.allowance(bob, alice), type(uint256).max);
    }

    // test permit function
    // reference https://book.getfoundry.sh/tutorials/testing-eip712 and solmate/src/test/ERC20.t.sol
    function testPermit() public {
        uint256 deadline = block.timestamp;
        // generate digest of permit
        bytes32 diagest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                instance.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, bob, alice, 1 ether, 0, deadline)) // owner, spender, value, nonce, deadline
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPrivateKey,
            diagest
        );
        // expect approval event
        vm.expectEmit(true, true, false, true, address(instance));
        emit Approval(bob, alice, 1 ether);
        instance.permit(bob, alice, 1 ether, deadline, v, r, s); // anyone can verify, need not to prank
        assertEq(instance.allowance(bob, alice), 1 ether);
        assertEq(instance.nonces(bob), 1); // nonce increment
    }

    function testPermitOverDeadline() public {
        uint256 deadline = block.timestamp;
        // generate digest of permit
        bytes32 diagest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                instance.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, bob, alice, 1 ether, 0, deadline)) // owner, spender, value, nonce, deadline
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPrivateKey,
            diagest
        );

        vm.warp(deadline + 1); // set block.timestamp
        vm.expectRevert("PERMIT_DEADLINE_EXPIRED");
        instance.permit(bob, alice, 1 ether, deadline, v, r, s); // anyone can verify, need not to prank
    }

    function testPermitInvalidSigner() public {
        uint256 deadline = block.timestamp;
        // generate digest of permit
        bytes32 diagest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                instance.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, bob, alice, 1 ether, 0, deadline)) // owner, spender, value, nonce, deadline
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPrivateKey,
            diagest
        );

        vm.expectRevert("INVALID_SIGNER");
        instance.permit(address(1), alice, 1 ether, deadline, v, r, s); // anyone can verify, need not to prank
    }
}
