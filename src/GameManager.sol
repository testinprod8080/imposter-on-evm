// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract GameManager {
  uint immutable maxPlayers;

  // @dev do not reorder to avoid breaking changes. Add new states at the end
  enum GameStates { 
    NotStarted, 
    Started, 
    Ended 
  }
  GameStates public gameState = GameStates.NotStarted;

  uint public numPlayers = 0;
  mapping(address => bool) public players;

  constructor(uint maxPlayers_) {
    maxPlayers = maxPlayers_;
  }

  function join() external {
    require(players[msg.sender] == false, "You have already joined");
    require(numPlayers < maxPlayers, "Game is full");
    require(gameState == GameStates.NotStarted, "Cannot join if game has already started or ended");
    players[msg.sender] = true;
    numPlayers++;
  }

  function leave() external {
    require(players[msg.sender], "You cannot leave a game you have not joined");
    players[msg.sender] = false;
    numPlayers--;
  }

  function changeGameState(uint gameStateIndex) public {
    require(gameState != GameStates(gameStateIndex), "Already in that state");
    require(gameState != GameStates.Ended, "Game has already ended");
    require(
      (gameState != GameStates.Started) && (GameStates(gameStateIndex) != GameStates.NotStarted), 
      "Game has already started"
    );
    gameState = GameStates(gameStateIndex);
  }
}