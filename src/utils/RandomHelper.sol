// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library RandomHelper {
  function pickRandomFromArray(uint numOfPicks, uint arraySize, string memory salt
  ) 
    external 
    view
    returns (uint[] memory indices_) 
  {
    uint[] memory indices = new uint[](numOfPicks);

    // last number is 0 most of the time, so add one and discard last number
    for (uint i = 0; i < numOfPicks; i++) {
      uint num = getPseudoRandom(arraySize, i, salt, indices);
      indices[i] = num;
    }
    return indices;
  }

  function getPseudoRandom(
    uint arraySize, 
    uint index, 
    string memory salt,
    uint[] memory pickedNumArray
  )
    private 
    view 
    returns (uint) 
  {
    uint pseudoRandomNum = uint(keccak256(abi.encodePacked(
      salt,
      block.difficulty,
      block.timestamp,
      index
    ))) % arraySize;

    return getNextIfAlreadyPicked(pseudoRandomNum, pickedNumArray);
  }

  function getNextIfAlreadyPicked(uint numToCheck, uint[] memory array) 
    private 
    pure 
    returns (uint) 
  {
    if (isPicked(numToCheck, array))
      return getNextIfAlreadyPicked(numToCheck + 1, array);
    else
      return numToCheck;
  }

  function isPicked(uint numToCheck, uint[] memory array) private pure returns (bool) {
    for (uint i = 0; i < array.length; i++) {
      if (array[i] == numToCheck)
        return true;
    }
    return false;
  }
}