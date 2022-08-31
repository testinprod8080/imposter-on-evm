// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract GameManager {
  // @dev do not reorder enums to avoid breaking changes. Add new at the end
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
    int playerAddrIndex;
  }

  struct TopVotedPlayer {
    address addr;
    uint votes;
  }

  uint immutable maxPlayers;
  uint immutable minPlayers;
  uint immutable voteCallCooldown;
  uint immutable tasksCompletedToWin = 5;

  uint public lastVoteCallTimestamp;
  uint public numAlivePlayers = 0;
  uint public numVotes = 0;
  uint public voteRound = 0;
  uint public tasksCompleted = 0;
  mapping(address => PlayerState) public players;
  mapping(uint => mapping(address => uint)) public votes;
  mapping(uint => mapping(address => bool)) public voted;
  GameStates public gameState = GameStates.NotStarted;
  GameOutcomes public gameOutcome = GameOutcomes.Stalemate;

  address[] private playerAddresses;
  address[] private realOnes;
  address[] private imposters;
  TopVotedPlayer[] private topVotedPlayers;

  modifier onlyPlayer(address player) {
    require(
      players[player].joined == true, 
      "Player did not join this game"
    );
    _;
  }

  modifier onlyAlive(address player) {
    require(
      players[player].alive == true, 
      "Player is not alive"
    );
    _;
  }

  modifier correctGameState(GameStates expectedGameState, string memory errorMsg) {
    require(
      gameState == expectedGameState,
      errorMsg
    );
    _;
  }

  constructor(
    uint maxPlayers_, 
    uint minPlayers_, 
    uint voteCallCooldown_
  ) {
    require(minPlayers_ > 3, "Need at least four players");
    require(minPlayers_ <= maxPlayers_, "Minimum players must be less than max");

    maxPlayers = maxPlayers_;
    minPlayers = minPlayers_;
    voteCallCooldown = voteCallCooldown_;
  }

  function join() 
    external 
    correctGameState(
      GameStates.NotStarted, 
      "Current game state does not allow joining"
    )
  {
    require(players[msg.sender].joined == false, "You have already joined");
    require(playerAddresses.length < maxPlayers, "Game is full");

    players[msg.sender] = PlayerState({ 
      joined: true, 
      alive: true,
      playerAddrIndex: int(playerAddresses.length)
    });

    playerAddresses.push(msg.sender);
  }

  function leave() external onlyPlayer(msg.sender) {
    removeFromPlayerAddress(uint(players[msg.sender].playerAddrIndex));

    players[msg.sender] = PlayerState({ 
      joined: false, 
      alive: false,
      playerAddrIndex: -1
    });
  }

  function start() 
    external 
    onlyPlayer(msg.sender)
  {
    require(
      gameState == GameStates.NotStarted || gameState == GameStates.Voting,
      "Current game state does not allow starting game"
    );
    require(playerAddresses.length >= minPlayers, "Not enough players to start game");

    numAlivePlayers = playerAddresses.length;

    setTeams();

    lastVoteCallTimestamp = block.timestamp;
    changeGameState(GameStates.Started);
  }

  // TODO input paramaters should be private
  // TODO should not be able to connect a resulting state to the call txn
  function doAction(uint action, address target) 
    external 
    onlyPlayer(msg.sender)
    correctGameState(
      GameStates.Started, 
      "Current game state does not allow actions"
    )
  {
    if (GameActions(action) == GameActions.CompleteTask) 
      completeTaskAction();
    else if (GameActions(action) == GameActions.KillPlayer) 
      killPlayerAction(target);
  }

  function callVote() 
    external 
    onlyPlayer(msg.sender)
    onlyAlive(msg.sender) 
    correctGameState(GameStates.Started, "Game must be started to call a vote")
  {
    require(
      block.timestamp - lastVoteCallTimestamp >= voteCallCooldown, 
      "Call vote cooldown still in effect"
    );

    changeGameState(GameStates.Voting);
    voteRound++;
  }

  function vote(address target) 
    external 
    onlyPlayer(msg.sender)
    onlyAlive(msg.sender) 
    onlyPlayer(target)
    onlyAlive(target)
    correctGameState(GameStates.Voting, "Current game state does not allow voting")
  {
    require(voted[voteRound][msg.sender] == false, "You already voted");

    votes[voteRound][target]++;
    numVotes++;
    setTopVotedPlayer(target, votes[voteRound][target]);

    if (numVotes == numAlivePlayers)
      killTopVotedPlayer();

    voted[voteRound][msg.sender] = true;
  }

  function getPlayerCount() public view returns(uint count) {
    return playerAddresses.length;
  }

  function getImposterCount() public view returns(uint count) {
    return imposters.length;
  }

  function getRealOnesCount() public view returns(uint count) {
    return realOnes.length;
  }

  function changeGameState(GameStates newGameState) private {
    require(gameState != GameStates.Ended, "Game has already ended");
    if (newGameState == GameStates.NotStarted) {
      require(
        gameState != GameStates.Started, 
        "Game has already started"
      );
    }

    gameState = newGameState;
  }

  function setTopVotedPlayer(address playerToCheck, uint voteCnt) private {
    if (topVotedPlayers.length > 0) {
      uint topVotes = topVotedPlayers[0].votes;

      if (voteCnt > topVotes) {
        delete topVotedPlayers;

        topVotedPlayers.push(TopVotedPlayer({ addr: playerToCheck, votes: voteCnt }));
      } else if (voteCnt == topVotes) {
        topVotedPlayers.push(TopVotedPlayer({ addr: playerToCheck, votes: voteCnt }));
      }
    } else {
      topVotedPlayers.push(TopVotedPlayer({ addr: playerToCheck, votes: voteCnt }));
    }
  }

  function killTopVotedPlayer() private {
    if (topVotedPlayers.length == 1) {
      players[topVotedPlayers[0].addr].alive = false;
      numAlivePlayers--;
    }
    resetVotes();
    bool winConditionMet = resolveWinConditionsByAlivePlayers();

    if (winConditionMet == false) {
      changeGameState(GameStates.Started);
      lastVoteCallTimestamp = block.timestamp;
    }
  }

  function resetVotes() private {
    delete topVotedPlayers;
    numVotes = 0;
  }

  function removeFromPlayerAddress(uint index) private {
    if (index < playerAddresses.length - 1) {
      for (uint i = index; i < playerAddresses.length - 1; i++) {
        playerAddresses[i] = playerAddresses[i + 1];
      }
    }
    playerAddresses.pop();
  }

  function setTeams() private {
    uint numImposters = playerAddresses.length / 4;

    for (uint i = 0; i < playerAddresses.length; i++) {
      // TODO needs to be random
      if (imposters.length < numImposters)
        imposters.push(playerAddresses[i]);
      else
        realOnes.push(playerAddresses[i]);
    }
  }

  function completeTaskAction() private {
    tasksCompleted++;

    resolveWinConditionsByTasks();
  }

  function killPlayerAction(address target) private {
    require(players[msg.sender].alive == true, "Action rejected");
    require(players[target].alive == true, "Action rejected");
    require(isImposter(msg.sender), "Action rejected");
    
    players[target].alive = false;

    if (numAlivePlayers > 0) numAlivePlayers--;

    resolveWinConditionsByAlivePlayers();
  }

  function resolveWinConditionsByAlivePlayers() private returns (bool winConditionMet) {
    uint aliveImposters = 0;
    for (uint i = 0; i < imposters.length; i++) {
      if (players[imposters[i]].alive)
        aliveImposters++;
    }

    if (aliveImposters <= 0) {
      changeGameState(GameStates.Ended);
      gameOutcome = GameOutcomes.RealOnesWin;
      return true;
    }

    uint aliveRealOnes = 0;
    for (uint i = 0; i < realOnes.length; i++) {
      if (players[realOnes[i]].alive)
        aliveRealOnes++;
    }

    if (aliveRealOnes <= aliveImposters) {
      changeGameState(GameStates.Ended);
      gameOutcome = GameOutcomes.ImpostersWin;
      return true;
    }

    return false;
  }

  function resolveWinConditionsByTasks() private returns (bool winConditionMet) {
    if (tasksCompleted >= tasksCompletedToWin) {
      changeGameState(GameStates.Ended);
      gameOutcome = GameOutcomes.RealOnesWin;
      return true;
    }

    return false;
  }

  function isImposter(address playerToCheck) private view returns (bool isImposter_) {
    for (uint i = 0; i < imposters.length; i++) {
      if (imposters[i] == playerToCheck)
        return true;
    }

    return false;
  }
}