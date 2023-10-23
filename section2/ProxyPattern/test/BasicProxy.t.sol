// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { testERC20 } from "../src/test/testERC20.sol";
import { testERC721 } from "../src/test/testERC721.sol";
import { MultiSigWallet } from "../src/MultiSigWallet/MultiSigWallet.sol";
// import { BasicProxy } from "../src/BasicProxy.sol";
import { BasicProxy } from "../src/Answers/BasicProxy.ans.sol";

contract BasicProxyTest is Test {

  address public admin = makeAddr("admin");
  address public alice = makeAddr("alice");
  address public bob = makeAddr("bob");
  address public carol = makeAddr("carol");
  address public receiver = makeAddr("receiver");

  MultiSigWallet public wallet;
  BasicProxy public proxy;
  MultiSigWallet public proxyWallet;

  testERC20 public erc20;
  testERC721 public erc721;

  function setUp() public {
    vm.prank(admin);
    wallet = new MultiSigWallet([alice, bob, carol]);
    proxy = new BasicProxy(address(wallet));
    vm.deal(address(proxy), 100 ether);
    // proxyWallet is a contract that should be treated as a MultiSigWallet

    erc20 = new testERC20();
    erc721 = new testERC721();
  }

  function test_updateOwner() public {
    // 1. try to update Owner

    // 2. check the owner1 is alice, owner2 is bob and owner3 is carol
  }

  function test_submit_tx() public {
    // 1. prank as one of the owner

    // 2. submit a transaction that transfer 10 ether to bob

    // Does it success? Why?
  }

  function test_call_initialize_and_check() public {
    // 1. call initialize function

    // 2. check the owner1, owner2, owner3 is initialized
  }

  function test_call_initialize_and_submit_tx() public {

    // 1. call initialize function

    // 2. submit a transaction that transfer 10 ether to bob

    // 3. check the transaction is submitted
  }

}