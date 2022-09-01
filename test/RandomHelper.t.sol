// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/utils/RandomHelper.sol";

contract GameManagerTest is Test {

  address[] private addresses = [
    address(0),
    address(1),
    address(2),
    address(3),
    address(4),
    address(5),
    address(6),
    address(7),
    address(8),
    address(9)
  ];

  function setUp() public {}

  function testRandomPickerFromArray() public {
    // arrange
    uint randomPicks = 3;
    vm.difficulty(1000000080948);
    vm.warp(16410708038948390);

    // act
    (address[] memory pickedArray, address[] memory remainderArray) = RandomHelper.pickRandomFromArray(
      randomPicks, 
      addresses,
      "mySaltdlsajdoejodjlajaskllkdsfjoshfoshe"
    );
    
    // assert
    assertEq(pickedArray.length, randomPicks);
    assertEq(remainderArray.length, addresses.length - randomPicks);
  }

  function testFuzzRandomPickerFromArray(
      uint randomPicks, 
      string memory salt
  ) public {
    address[] memory pickedArray;
    address[] memory remainderArray;

    // arrange
    randomPicks = bound(randomPicks, 1, addresses.length - 1);
    require(randomPicks >= 1 && randomPicks < addresses.length);

    // act
    (pickedArray, remainderArray) = RandomHelper.pickRandomFromArray(
      randomPicks, 
      addresses,
      salt
    );
    
    // assert
    assertEq(pickedArray.length, randomPicks);
    assertEq(remainderArray.length, addresses.length - randomPicks);
  }
}