// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/utils/RandomHelper.sol";

contract GameManagerTest is Test {

  function setUp() public {}

  function testRandomPickerFromArray() public {
    // arrange
    uint randomPicks = 1;
    vm.difficulty(1000000080948);
    vm.warp(16410708038948390);

    // act
    uint[] memory results = RandomHelper.pickRandomFromArray(
      randomPicks, 
      4,
      "mySaltdlsajdoejodjlajaskllkdsfjoshfoshe"
    );
    
    // assert
    assertEq(results.length, randomPicks);
    for (uint i = 0; i < results.length; i++){
      console.logUint(results[i]);
    }
  }

  function testFuzzRandomPickerFromArray(
      uint randomPicks, 
      uint arraySize,
      string memory salt
  ) public {
    // arrange
    arraySize = bound(arraySize, 4, 100);
    require(arraySize >= 1 && arraySize <= 100);
    randomPicks = bound(randomPicks, 1, arraySize);
    require(randomPicks >= 1 && randomPicks <= arraySize);

    // act
    uint[] memory results = RandomHelper.pickRandomFromArray(
      randomPicks, 
      arraySize,
      salt
    );
    
    // assert
    assertEq(results.length, randomPicks);
  }
}