# Game Design Thoughts

## Q: Does it matter if players can sabotage their team by calling actions against their own objectives?
A: No, but could be a sybil attack vector. Someone could join as multiple players hoping to be on both teams. Attack incentive is stornger with rewards at stake.

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
    - Maybe require complete task to have a `start()` and `finish()` action to fully complete and different tasks have different time-to-complete
1. Time delayed execution? - how to execute this in contract?

# Actions

## Imposter
- startTask() - does nothing
- finishTask() - does nothing
- killPlayer()
- sabotage() - stops and prevents task work
- fix() - does nothing

## Real Ones
- startTask(task)
- finishTask(task)
- fix() - reset game when sabotaged
- checkImposters() - only callable once game has ended

## Shared
- callVote()
- vote()
- checkDead()