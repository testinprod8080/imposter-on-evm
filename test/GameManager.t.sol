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
  enum GameOutcomes {
    Stalemate,
    ImpostersWin,
    RealOnesWin
  }
  struct PlayerState {
    bool joined;
    bool alive;
  }

  address[] private players = [
    address(1),
    address(2),
    address(3),
    address(4),
    address(5),
    address(6),
    address(7),
    address(8),
    address(9),
    address(10)
  ];

  address[] imposters;

  GameManager public gameManager;

  function setUp() public {
    gameManager = new GameManager(10, 4, 0);
    vm.startPrank(players[0]);
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
    changePrank(players[1]);
    gameManager.join();
    changePrank(players[2]);
    gameManager.join();
    changePrank(players[3]);
    gameManager.join();
    changePrank(players[4]);

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
    (bool joined,,) = gameManager.players(players[0]);
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
    (bool joined,,) = gameManager.players(players[0]);
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
    changePrank(players[1]);
    gameManager.join();
    changePrank(players[2]);
    gameManager.join();
    changePrank(players[3]);
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
    assertEq(gameManager.tasksCompleted(), 1);
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
    startGame(4);
    changePrank(players[0]);
    gameManager.doAction(uint(GameActions.KillPlayer), players[1]);

    // act & assert
    vm.expectRevert(bytes("Action rejected"));
    gameManager.doAction(uint(GameActions.KillPlayer), players[1]);
  }

  function testCannotKillPlayerNotJoined() public {
    // arrange
    changePrank(players[4]);
    gameManager.join();
    gameManager.leave();
    startGame(4);

    // act & assert
    changePrank(players[0]);
    vm.expectRevert(bytes("Action rejected"));
    gameManager.doAction(uint(GameActions.KillPlayer), players[4]);
  }

  function testCannotKillWhileDead() public {
    // arrange
    startGame(10);
    changePrank(players[1]);
    gameManager.doAction(uint(GameActions.KillPlayer), players[0]);

    // act & assert
    changePrank(players[0]);
    vm.expectRevert(bytes("Action rejected"));
    gameManager.doAction(uint(GameActions.KillPlayer), players[3]);
  }

  function testCannotKillIfNotImposter() public {
    // arrange
    startGame(4);

    // act & assert
    vm.expectRevert("Action rejected");
    gameManager.doAction(uint(GameActions.KillPlayer), players[1]);
  }

  function testKill() public {
    // arrange
    startGame(4);

    // act
    changePrank(players[0]);
    gameManager.doAction(uint(GameActions.KillPlayer), players[1]);

    // assert
    (, bool alive,) = gameManager.players(players[1]);
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
    startGame(4);
    changePrank(players[0]);
    gameManager.doAction(uint(GameActions.KillPlayer), players[1]);

    // act & assert
    changePrank(players[1]);
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
    startGame(4);
    skip(VOTECALL_COOLDOWN);
    gameManager.callVote();
    gameManager.vote(players[1]);
    changePrank(players[2]);
    gameManager.vote(players[1]);
    changePrank(players[1]);
    gameManager.vote(players[1]);
    changePrank(players[0]);
    gameManager.vote(players[1]);

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
    gameManager.vote(players[0]);
  }

  function testCannotVoteIfNotPlayer() public {
    // arrange
    gameManager.join();
    changePrank(players[1]);

    // act & assert
    vm.expectRevert(bytes("Player did not join this game"));
    gameManager.vote(players[0]);
  }

  function testCannotVoteIfDead() public {
    // arrange
    startGame(4);
    changePrank(players[0]);
    gameManager.doAction(uint(GameActions.KillPlayer), players[2]);
    gameManager.callVote();

    // act & assert
    vm.expectRevert(bytes("Player is not alive"));
    changePrank(players[2]);
    gameManager.vote(players[0]);
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
    gameManager.vote(players[1]);
  }

  function testCannotVoteForDeadPlayer() public {
    // arrange
    startGame(4);
    changePrank(players[0]);
    gameManager.doAction(uint(GameActions.KillPlayer), players[1]);
    gameManager.callVote();
    
    // act & assert
    vm.expectRevert(bytes("Player is not alive"));
    gameManager.vote(players[1]);
  }

  function testCannotVoteMoreThanOnce() public {
    // arrange
    gameManager.join();
    changePrank(players[1]);
    gameManager.join();
    stdstore
      .target(address(gameManager))
      .sig("gameState()")
      .checked_write(uint(GameStates.Voting));
    gameManager.vote(players[0]);

    // act & assert
    vm.expectRevert(bytes("You already voted"));
    gameManager.vote(players[0]);
  }

  function testVote() public {
    // arrange
    startGame(4);
    gameManager.callVote();

    // act
    gameManager.vote(players[1]);
    changePrank(players[2]);
    gameManager.vote(players[1]);
    changePrank(players[1]);
    gameManager.vote(players[1]);
    changePrank(players[0]);
    gameManager.vote(players[1]);

    // assert
    assertEq(uint(gameManager.gameState()), uint(GameStates.Started));
    assertEq(gameManager.votes(1, players[1]), 4);
  }

  function testVoteNoPlayerDiesWhenTied() public {
    // arrange
    startGame(4);
    gameManager.callVote();

    // act
    gameManager.vote(players[0]);
    changePrank(players[2]);
    gameManager.vote(players[0]);
    changePrank(players[1]);
    gameManager.vote(players[3]);
    changePrank(players[0]);
    gameManager.vote(players[3]);

    // assert
    (, bool aliveP1,) = gameManager.players(players[0]);
    assertTrue(aliveP1);
    (, bool aliveP4,) = gameManager.players(players[3]);
    assertTrue(aliveP4);
  }

  function testVotePlayerDiesAndSetsGameBackToStarted() public {
    // arrange
    startGame(4);
    gameManager.callVote();

    // act
    gameManager.vote(players[0]);
    changePrank(players[2]);
    gameManager.vote(players[3]);
    changePrank(players[1]);
    gameManager.vote(players[3]);
    changePrank(players[0]);
    gameManager.vote(players[3]);

    // assert - dead player
    (, bool alive,) = gameManager.players(players[3]);
    assertFalse(alive);

    // assert - game state is started
    assertEq(uint(gameManager.gameState()), uint(GameStates.Started));

    // assert - reset votes
    assertEq(gameManager.numVotes(), 0);
  }

  function testVoteMultiRoundMultipleDead() public {
    // arrange
    startGame(4);
    gameManager.callVote();

    gameManager.vote(players[0]);
    changePrank(players[2]);
    gameManager.vote(players[3]);
    changePrank(players[1]);
    gameManager.vote(players[3]);
    changePrank(players[0]);
    gameManager.vote(players[1]);

    // act - round 2
    gameManager.callVote();
    gameManager.vote(players[1]);
    changePrank(players[1]);
    gameManager.vote(players[0]);
    changePrank(players[2]);
    gameManager.vote(players[1]);

    // assert - dead player
    (, bool aliveP4,) = gameManager.players(players[3]);
    assertFalse(aliveP4);
    (, bool aliveP2,) = gameManager.players(players[1]);
    assertFalse(aliveP2);
  }

  function testOneImposterAssigned() public {
    // arrange
    gameManager.join();
    changePrank(players[1]);
    gameManager.join();
    changePrank(players[2]);
    gameManager.join();
    changePrank(players[3]);
    gameManager.join();
    changePrank(players[4]);
    gameManager.join();

    // act
    gameManager.start();

    // assert
    assertEq(gameManager.getImposterCount(), 1);
    assertEq(gameManager.getRealOnesCount(), 4);
  }

  function testTwoImpostersAssigned() public {
    // arrange
    gameManager.join();
    changePrank(players[1]);
    gameManager.join();
    changePrank(players[2]);
    gameManager.join();
    changePrank(players[3]);
    gameManager.join();
    changePrank(players[4]);
    gameManager.join();
    changePrank(players[5]);
    gameManager.join();
    changePrank(players[6]);
    gameManager.join();
    changePrank(players[7]);
    gameManager.join();
    changePrank(players[8]);
    gameManager.join();
    changePrank(players[9]);
    gameManager.join();

    // act
    gameManager.start();

    // assert
    assertEq(gameManager.getImposterCount(), 2);
    assertEq(gameManager.getRealOnesCount(), 8);
  }
  
  //  Real One per Imposter left
  function testImpostersWinByKills() public {
    // arrange
    startGame(4);

    // act
    changePrank(players[0]);
    gameManager.doAction(uint(GameActions.KillPlayer), players[1]);
    gameManager.doAction(uint(GameActions.KillPlayer), players[2]);

    // assert
    assertEq(uint(gameManager.gameState()), uint(GameStates.Ended));
    assertEq(uint(gameManager.gameOutcome()), uint(GameOutcomes.ImpostersWin));
  }

  function testRealOnesWinByVote() public {
    // arrange
    startGame(4);

    // act
    gameManager.callVote();
    changePrank(players[0]);
    gameManager.vote(players[0]);
    changePrank(players[1]);
    gameManager.vote(players[0]);
    changePrank(players[2]);
    gameManager.vote(players[0]);
    changePrank(players[3]);
    gameManager.vote(players[0]);

    // assert
    assertEq(uint(gameManager.gameState()), uint(GameStates.Ended));
    assertEq(uint(gameManager.gameOutcome()), uint(GameOutcomes.RealOnesWin));
  }

  // Helper functions
  function startGame(uint numPlayers) private {
    for (uint i = 0; i < numPlayers; i++) {
      changePrank(players[i]);
      gameManager.join();
    }
    gameManager.start();
  }

  function testRealOnesWinByTasks() public {
    // arrange
    startGame(4);

    // act
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));
    gameManager.doAction(uint(GameActions.CompleteTask), address(0));

    // assert
    assertEq(uint(gameManager.gameState()), uint(GameStates.Ended));
    assertEq(uint(gameManager.gameOutcome()), uint(GameOutcomes.RealOnesWin));
  }
}