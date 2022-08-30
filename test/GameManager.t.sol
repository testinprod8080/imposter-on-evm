// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GameManager.sol";

contract GameManagerTest is Test {
  using stdStorage for StdStorage;

  enum GameStates { 
    NotStarted, 
    Started, 
    Ended,
    Voting
  }
  enum GameActions {
    CompleteTask,
    KillPlayer
  }
  struct PlayerState {
    bool joined;
    bool alive;
  }

  address constant PLAYER1 = address(1);
  address constant PLAYER2 = address(2);
  address constant PLAYER3 = address(3);
  address constant PLAYER4 = address(4);
  address constant PLAYER5 = address(5);
  address constant PLAYER6 = address(6);
  address constant PLAYER7 = address(7);
  address constant PLAYER8 = address(8);
  address constant PLAYER9 = address(9);
  address constant PLAYER10 = address(10);

  address[] imposters;

  GameManager public gameManager;

  function setUp() public {
    gameManager = new GameManager(10, 4, 0);
    vm.startPrank(PLAYER1);
  }

  function testCannotHaveOneMinPlayer() public {
    vm.expectRevert(bytes("Need at least four players"));
    new GameManager(4, 3, 0);
  }

  function testCannotHaveMoreMinThanMaxPlayers() public {
    vm.expectRevert(bytes("Minimum players must be less than max"));
    new GameManager(0, 4, 0);
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
    gameManager = new GameManager(4, 4, 0);
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    changePrank(PLAYER3);
    gameManager.join();
    changePrank(PLAYER4);
    gameManager.join();
    changePrank(PLAYER5);

    // act & assert
    vm.expectRevert(bytes("Game is full"));
    gameManager.join();
  }

  function testCannotJoinStarted() public {
    // arrange
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));

    // act & assert
    vm.expectRevert(bytes("Current game state does not allow joining"));
    gameManager.join();
  }

  function testJoin() public {
    // act
    gameManager.join();

    // assert
    assertEq(gameManager.getPlayerCount(), 1);
    (bool joined,,) = gameManager.players(PLAYER1);
    assertTrue(joined);
  }

  function testCannotLeaveIfNotJoined() public {
    vm.expectRevert(bytes("Player did not join this game"));
    gameManager.leave();
  }

  function testLeave() public {
    // arrange
    gameManager.join();

    // act
    gameManager.leave();

    // assert
    assertEq(gameManager.getPlayerCount(), 0);
    (bool joined,,) = gameManager.players(PLAYER1);
    assertFalse(joined);
  }

  function testCannotStartWhenNotJoined() public {
    vm.expectRevert(bytes("Player did not join this game"));
    gameManager.start();
  }

  function testCannotStartWhenAlreadyStarted() public {
    // arrange
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));

    // act & assert
    vm.expectRevert(bytes("Current game state does not allow starting game"));
    gameManager.start();
  }

  function testCannotStartWithNotEnoughPlayers() public {
    // arrange
    gameManager.join();

    // act & assert
    vm.expectRevert(bytes("Not enough players to start game"));
    gameManager.start();
  }

  function testStart() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    changePrank(PLAYER3);
    gameManager.join();
    changePrank(PLAYER4);
    gameManager.join();

    // act
    gameManager.start();

    // assert
    assertEq(uint(gameManager.gameState()), uint(GameStates.Started));
  }

  function testCannotDoActionWhenNotStarted() public {
    gameManager.join();
    vm.expectRevert(bytes("Current game state does not allow actions"));
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));
  }

  function testCannotDoActionWhenEnded() public {
    // arrange
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Ended));

    // act & assert
    vm.expectRevert(bytes("Current game state does not allow actions"));
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));
  }

  function testCompleteTask() public {
    // arrange
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));

    // act
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));

    // assert
    assertEq(gameManager.points(), 1);
  }

  function testCannotDoActionWhenNotJoined() public {
    // arrange
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));

    // act
    vm.expectRevert(bytes("Player did not join this game"));
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));
  }

  function testCannotKillDeadPlayer() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER1);

    // act & assert
    vm.expectRevert(bytes("Action rejected"));
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER1);
  }

  function testCannotKillPlayerNotJoined() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    gameManager.leave();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));

    // act & assert
    vm.expectRevert(bytes("Action rejected"));
    changePrank(PLAYER1);
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER2);
  }

  function testCannotKillWhileDead() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER1);

    // act & assert
    changePrank(PLAYER1);
    vm.expectRevert(bytes("Action rejected"));
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER2);
  }

  function testKill() public {
    // arrange
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));

    // act
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER1);

    // assert
    (, bool alive,) = gameManager.players(PLAYER1);
    assertFalse((alive));
  }

  function testCannotCallVoteIfNotJoined() public {
    vm.expectRevert(bytes("Player did not join this game"));
    gameManager.callVote();
  }

  function testCannotCallVoteIfNotStarted() public {
    gameManager.join();
    vm.expectRevert(bytes("Game must be started to call a vote"));
    gameManager.callVote();
  }

  function testCannotCallVoteIfAlreadyVoting() public {
    // arrange
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));
    gameManager.callVote();

    // act & assert
    vm.expectRevert(bytes("Game must be started to call a vote"));
    gameManager.callVote();
  }

  function testCannotCallVoteIfDead() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER1);

    // act & assert
    changePrank(PLAYER1);
    vm.expectRevert(bytes("Player is not alive"));
    gameManager.callVote();
  }

  function testCannotCallVoteUntilCooldownAfterStart() public {
    // arrange
    gameManager = new GameManager(4, 4, 10);
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));

    // act & assert
    vm.expectRevert(bytes("Call vote cooldown still in effect"));
    gameManager.callVote();
  }
  
  function testCannotCallVoteUntilCooldownAfterLastVoteCall() public {
    // arrange
    uint VOTECALL_COOLDOWN = 10;
    gameManager = new GameManager(4, 4, VOTECALL_COOLDOWN);
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    changePrank(PLAYER3);
    gameManager.join();
    changePrank(PLAYER4);
    gameManager.join();
    gameManager.start();
    skip(VOTECALL_COOLDOWN);
    gameManager.callVote();
    gameManager.vote(PLAYER2);
    changePrank(PLAYER3);
    gameManager.vote(PLAYER2);
    changePrank(PLAYER2);
    gameManager.vote(PLAYER2);
    changePrank(PLAYER1);
    gameManager.vote(PLAYER2);

    // act & assert
    vm.expectRevert(bytes("Call vote cooldown still in effect"));
    gameManager.callVote();
  }

  function testCallVote() public {
    // arrange
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));

    // act
    gameManager.callVote();

    // assert
    assertEq(uint(gameManager.gameState()), uint(GameStates.Voting));    
  }

  function testCannotVoteWhenNotInVoteCall() public {
    gameManager.join();
    vm.expectRevert(bytes("Current game state does not allow voting"));
    gameManager.vote(PLAYER1);
  }

  function testCannotVoteIfNotPlayer() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);

    // act & assert
    vm.expectRevert(bytes("Player did not join this game"));
    gameManager.vote(PLAYER1);
  }

  function testCannotVoteIfDead() public {
    // arrange
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER1);
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Voting));

    // act & assert
    vm.expectRevert(bytes("Player is not alive"));
    gameManager.vote(PLAYER1);
  }

  function testCannotVoteForNonPlayer() public {
    // arrange
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Voting));

    // act & assert
    vm.expectRevert(bytes("Player did not join this game"));
    gameManager.vote(PLAYER2);
  }

  function testCannotVoteForDeadPlayer() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Started));
    gameManager.doAction(uint(GameActions.KillPlayer), PLAYER1);
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Voting));
    
    // act & assert
    vm.expectRevert(bytes("Player is not alive"));
    gameManager.vote(PLAYER1);
  }

  function testCannotVoteMoreThanOnce() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Voting));
    gameManager.vote(PLAYER1);

    // act & assert
    vm.expectRevert(bytes("You already voted"));
    gameManager.vote(PLAYER1);
  }

  function testVote() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Voting));

    // act
    gameManager.vote(PLAYER1);

    // assert
    assertEq(gameManager.votes(0, PLAYER1), 1);
  }

  function testVoteNoPlayerDiesWhenTied() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    changePrank(PLAYER3);
    gameManager.join();
    changePrank(PLAYER4);
    gameManager.join();
    gameManager.start();
    gameManager.callVote();

    // act
    gameManager.vote(PLAYER1);
    changePrank(PLAYER3);
    gameManager.vote(PLAYER1);
    changePrank(PLAYER2);
    gameManager.vote(PLAYER4);
    changePrank(PLAYER1);
    gameManager.vote(PLAYER4);

    // assert
    (, bool aliveP1,) = gameManager.players(PLAYER1);
    assertTrue(aliveP1);
    (, bool aliveP4,) = gameManager.players(PLAYER4);
    assertTrue(aliveP4);
  }

  function testVotePlayerDiesAndSetsGameBackToStarted() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    changePrank(PLAYER3);
    gameManager.join();
    changePrank(PLAYER4);
    gameManager.join();
    gameManager.start();
    gameManager.callVote();

    // act
    gameManager.vote(PLAYER1);
    changePrank(PLAYER3);
    gameManager.vote(PLAYER4);
    changePrank(PLAYER2);
    gameManager.vote(PLAYER4);
    changePrank(PLAYER1);
    gameManager.vote(PLAYER4);

    // assert - dead player
    (, bool alive,) = gameManager.players(PLAYER4);
    assertFalse(alive);

    // assert - game state is started
    assertEq(uint(gameManager.gameState()), uint(GameStates.Started));

    // assert - reset votes
    assertEq(gameManager.numVotes(), 0);
  }

  function testVoteMultiRoundMultipleDead() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    changePrank(PLAYER3);
    gameManager.join();
    changePrank(PLAYER4);
    gameManager.join();
    gameManager.start();
    gameManager.callVote();

    gameManager.vote(PLAYER1);
    changePrank(PLAYER3);
    gameManager.vote(PLAYER4);
    changePrank(PLAYER2);
    gameManager.vote(PLAYER4);
    changePrank(PLAYER1);
    gameManager.vote(PLAYER2);

    // act - round 2
    gameManager.callVote();
    gameManager.vote(PLAYER2);
    changePrank(PLAYER2);
    gameManager.vote(PLAYER1);
    changePrank(PLAYER3);
    gameManager.vote(PLAYER2);

    // assert - dead player
    (, bool aliveP4,) = gameManager.players(PLAYER4);
    assertFalse(aliveP4);
    (, bool aliveP2,) = gameManager.players(PLAYER2);
    assertFalse(aliveP2);
  }

  function testOneImposterAssigned() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    changePrank(PLAYER3);
    gameManager.join();
    changePrank(PLAYER4);
    gameManager.join();
    changePrank(PLAYER5);
    gameManager.join();

    // act
    gameManager.start();

    // assert
    assertEq(gameManager.getImposterCount(), 1);
  }

  function testTwoImpostersAssigned() public {
    // arrange
    gameManager.join();
    changePrank(PLAYER2);
    gameManager.join();
    changePrank(PLAYER3);
    gameManager.join();
    changePrank(PLAYER4);
    gameManager.join();
    changePrank(PLAYER5);
    gameManager.join();
    changePrank(PLAYER6);
    gameManager.join();
    changePrank(PLAYER7);
    gameManager.join();
    changePrank(PLAYER8);
    gameManager.join();
    changePrank(PLAYER9);
    gameManager.join();
    changePrank(PLAYER10);
    gameManager.join();

    // act
    gameManager.start();

    // assert
    assertEq(gameManager.getImposterCount(), 2);
  }
}