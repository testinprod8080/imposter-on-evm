// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library RandomHelper {
  function pickRandomFromArray(
    uint numOfPicks, 
    address[] memory addresses, 
    string memory salt
  ) 
    external 
    view
    returns (address[] memory pickedArray_, address[] memory remainderArray_) 
  {
    require(addresses.length > numOfPicks, "Pick less than the size of the array");

    uint[] memory pickedIndices = new uint[](numOfPicks);
    address[] memory pickedArray = new address[](numOfPicks);
    bool[] memory isPicked = new bool[](addresses.length);

    for (uint i = 0; i < numOfPicks; i++) { 
      uint num = getPseudoRandomNumber(addresses, i, salt, pickedIndices);
      pickedIndices[i] = num;
      pickedArray[i] = addresses[num];
      isPicked[num] = true;
    }

    // put any addresses not picked into remainder array
    address[] memory remainderArray = new address[](addresses.length - numOfPicks);

    uint remainderCounter = 0;
    for (uint i = 0; i < addresses.length; i++) {
      if (isPicked[i])
        continue;
      
      remainderArray[remainderCounter] = addresses[i];
      remainderCounter++;
    }

    return (pickedArray, remainderArray);
  }

  function getPseudoRandomNumber(
    address[] memory addresses, 
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
      index,
      addresses
    ))) % addresses.length;

    return getNextIfAlreadyPicked(pseudoRandomNum, pickedNumArray, addresses.length);
  }

  function getNextIfAlreadyPicked(
    uint numToCheck, 
    uint[] memory numPickArray, 
    uint arraySize
  ) 
    private 
    pure 
    returns (uint) 
  {
    if (checkIfPicked(numToCheck, numPickArray)) {
      uint newNumToCheck;
      if (numToCheck == arraySize - 1)
        newNumToCheck = 0;
      else
        newNumToCheck = numToCheck + 1;

      return getNextIfAlreadyPicked(newNumToCheck, numPickArray, arraySize);
    }
    else
      return numToCheck;
  }

  function checkIfPicked(uint numToCheck, uint[] memory numPickArray) 
    private 
    pure 
    returns (bool) 
  {
    for (uint i = 0; i < numPickArray.length; i++) {
      if (numPickArray[i] == numToCheck)
        return true;
    }
    return false;
  }
}