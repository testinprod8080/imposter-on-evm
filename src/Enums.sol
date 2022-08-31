// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library Enums {
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
}