// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;


// Comments don't get more random than this, huh?


/// The different states of our supply chain
contract SupplyChainState {
    enum State { ForSale, Sold, Shipped, Received }
}
