// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library Structs {
  struct PlayerState {
    bool joined;
    bool alive;
    int playerAddrIndex;
  }

  struct TopVotedPlayer {
    address addr;
    uint votes;
  }

  struct TaskInProgress {
    uint id;
    uint startTime;
  }
}