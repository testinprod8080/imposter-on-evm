// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GameManager.sol";

contract GameManagerTest is Test {
  GameManager public gameManager;
  enum GameStates { NotStarted, Started, Ended }

  address constant PLAYER1 = address(0);
  address constant PLAYER2 = address(1);
  address constant PLAYER3 = address(2);
  address constant PLAYER4 = address(3);

  function setUp() public {
    gameManager = new GameManager(4);
    vm.startPrank(PLAYER1);
  }

  function testCannotJoinTwice() public {
    // arrange
    gameManager.join();

    // act & assert
    vm.expectRevert(bytes("You have already joined"));
    gameManager.join();
  }

  function testCannotJoinFullGame() public {
    // arrange
    gameManager = new GameManager(1);
    gameManager.join();
    changePrank(PLAYER2);

    // act & assert
    vm.expectRevert(bytes("Game is full"));
    gameManager.join();
  }

  function testCannotJoinStarted() public {
    // arrange
    gameManager.changeGameState(uint(GameStates.Started));

    // act & assert
    vm.expectRevert(bytes("Cannot join if game has already started or ended"));
    gameManager.join();
  }

  function testJoin() public {
    gameManager.join();
    assertEq(gameManager.numPlayers(), 1);
    assertTrue(gameManager.players(PLAYER1));
  }

  function testCannotLeaveIfNotJoined() public {
    vm.expectRevert(bytes("You cannot leave a game you have not joined"));
    gameManager.leave();
  }

  function testLeave() public {
    gameManager.join();
    gameManager.leave();
    assertEq(gameManager.numPlayers(), 0);
    assertFalse(gameManager.players(PLAYER1));
  }

  function testCannotChangeToSameGameState() public {
    vm.expectRevert(bytes("Already in that state"));
    gameManager.changeGameState(uint(GameStates.NotStarted));
  }

  function testCannotChangeEndedGameState() public {
    // arrange
    gameManager.changeGameState(uint(GameStates.Ended));

    // act & assert
    vm.expectRevert(bytes("Game has already ended"));
    gameManager.changeGameState(uint(GameStates.Started));
  }

  function testCannotChangeGameStateFromStartedToNotStarted() public {
    // arrange
    gameManager.changeGameState(uint(GameStates.Started));

    // act & assert
    vm.expectRevert(bytes("Game has already started"));
    gameManager.changeGameState(uint(GameStates.NotStarted));
  }
}