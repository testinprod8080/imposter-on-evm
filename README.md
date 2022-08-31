# Overview
Imposter is a hidden identity team (Imposters) versus team (Real Ones) blockchain game.

# Gameplay

## Set Up

A game host creates a new lobby and sets the minimum and maximum number of players. Once the minimum number of players have joined, starting the game randomly assigns players as Imposters or Real Ones.

## Win Conditions

### For Imposters
Imposters win if all Real Ones are dead or have left the game

### For Real Ones
Real Ones can win with either of the following conditions:
- All Imposters are dead or have left the game
- All tasks have been successfully completed. Every Real One player has to complete all tasks once

## Actions

### Imposter
- startTask - does nothing
- finishTask - does nothing
- killPlayer

### Real Ones
- startTask
- finishTask

### Shared
- callVote
- vote

## Tasks

Imposters can call this action to broadcast that they are doing an action while only pretending to do it.

For Real Ones, completing a task requires two actions:
1. Call doTask once to start the task
1. After the required time-to-complete has passed for the task started, call doTask again to finish the task

When a Real One has started a task, they cannot perform any other tasks unless they finish, leave unfinished, or a vote is called.

# Versions
## v0.1
- [x] Players will be able to play using a manually deployed contract. 
  - [x] join
  - [x] leave
- [x] Playable game with simple win conditions: Imposters kill, Real Ones complete tasks or vote out Imposters
  - [x] startTask
  - [x] finishTask
  - [x] killPlayer
  - [x] callVote
  - [x] vote
  - [ ] Random imposter assignment
- [ ] UI - specify contract address
  - [ ] join / leave
  - [ ] player list
  - [ ] invoke game actions
  - [ ] display game state
  - [ ] display action results
- No onchain privacy

## Future
- [ ] sabotage - stops and prevents task work
- [ ] fix 
  - does nothing for Imposters
  - repairs sabotaged thing
- [ ] checkImposters 
  - if Imposter, can call anytime to see who the other Imposters are
  - if Real One, only callable once game has ended
- [ ] checkDead
- [ ] Game factory contract
- [ ] UI: Game creator
- [ ] UI: List games
- [ ] Fog-of-war mechanic

## Game Design Thoughts
## Q: Does it matter if players can sabotage their team by calling actions against their own objectives?

A: No, but could be a sybil attack vector. Someone could join as multiple players hoping to be on both teams. Attack incentive is stronger with rewards at stake.

## Calling actions with a blame mechanic could be a feature

- Allows Imposters to cast suspicion on another player
- This should be a "delegate" mechanic for Real Ones. If it is something they also do, then helps mask Imposters actions when using this mechanic

## What needs to be private?

- isImposter : bool
- Action type : enum
- Result of action called : correlation

### isImposter

Requirements:
- Must be hidden from start of game until win condition is met
- Game engine needs to be able to check value to check win conditions

Options:
1. Commit & reveal? - not possible for game engine to know value unless it also knows pre-hash values
1. zkSNARK? - how can engine check if player is an imposter?

### Action type

Requirements:
- Other players cannot know what action is being called

Options:
1. zkSNARK? - action type and any other calldata as private inputs

### Result of action called

Requirements:
- Other players should know action results but should not be able to connect an action to its result both in transaction tracing and time correlation (e.g. this happened right after this was called)

Options:
1. Commit actions as bundle & execute randomly? 
    - Randomness requires VRF. Will random execution be good gameplay?
    - This makes the game turn-based
1. Different time-to-complete for different actions?
    - Would allow Imposters to time their actions with someone else's to create confusion, but requires Real Ones action time-to-complete to have some unpredictability so it cannot be easily calculated
    - Maybe require complete task to have a `start` and `finish` action to fully complete and different tasks have different time-to-complete
1. Time delayed execution? - how to execute this in contract?