
## project
git clone git@github.com:cds-blog-code-samples/MarketSample.git

The managed ganache that truffle spins up takes an awefully long time to run. For example this particular tests shows a significant difference in managed and unmanaged. 

```
    ✓ testBuyerAndSellerAreDifferentActors (61ms)   (unmanaged)
    ✓ testBuyerAndSellerAreDifferentActors (1073ms) (managed)
```

See full test results in output details 

## truffle test with separate ganache

  - Start ganache in one terminal 
  - Run `truffle test` in another.


<details><summary>output</summary>

```

Compiling your contracts...
===========================
> Compiling ./contracts/Migrations.sol
> Compiling ./contracts/SupplyChain.sol
> Compiling ./contracts/SupplyChainState.sol
> Compiling ./test/Proxy.sol
> Compiling ./test/TestSupplyChain.sol
> Compilation warnings encountered:

    project:/contracts/Migrations.sol:13:5: Warning: Visibility for constructor is ignored. If you want the contract to be non-deployable, making it "abstract" is sufficient.
    constructor()
    ^ (Relevant source part starts here and spans across multiple lines).

> Artifacts written to /tmp/test--179226-v4PZYKuNy5ls
> Compiled successfully using:
   - solc: 0.7.3+commit.9bfce1f6.Emscripten.clang



  TestSupplyChain
    ✓ testBuyerAndSellerAreDifferentActors (61ms)
    ✓ testItemCanBePutOnSale (114ms)
    ✓ testUserDoesNotPaysTheRightPrice (56ms)
    ✓ testUserPaysTheRightPrice (62ms)
    ✓ testItemCannotBePurchasedTwice (83ms)
    ✓ testRandomUserCannotShipItem (73ms)
    ✓ testSellerCanShipItem (76ms)
    ✓ testCannotShipAnItemThatIsNotSold (46ms)
    ✓ testNonBuyerCannotSetItemAsReceived (82ms)
    ✓ testBuyerCanSetItemAsReceived (93ms)
    ✓ testBuyerCannotReceiveItemNotShipped (84ms)

  Contract: SupplyChain
    ✓ should add an item with the provided name and price
    ✓ should emit a LogForSale event when an item is added
    ✓ should allow someone to purchase an item and update state accordingly (61ms)
    ✓ should error when not enough value is sent when purchasing an item (52ms)
    ✓ should emit LogSold event when and item is purchased (54ms)
    ✓ should revert when someone that is not the seller tries to call shipItem() (57ms)
    ✓ should allow the seller to mark the item as shipped (60ms)
    ✓ should emit a LogShipped event when an item is shipped (53ms)
    ✓ should allow the buyer to mark the item as received (77ms)
    ✓ should revert if an address other than the buyer calls receiveItem() (69ms)
    ✓ should emit a LogReceived event when an item is received (67ms)


  22 passing (7s)

```

</details>

## truffle test with managed ganache instance

  - Stop Ganache if running.
  - Change the development network to `xdevelopment` or remove it from truffle-config.js

<details><summary>output</summary>

```

Compiling your contracts...
===========================
> Compiling ./contracts/Migrations.sol
> Compiling ./contracts/SupplyChain.sol
> Compiling ./contracts/SupplyChainState.sol
> Compiling ./test/Proxy.sol
> Compiling ./test/TestSupplyChain.sol
> Compilation warnings encountered:

    project:/contracts/Migrations.sol:13:5: Warning: Visibility for constructor is ignored. If you want the contract to be non-deployable, making it "abstract" is sufficient.
    constructor()
    ^ (Relevant source part starts here and spans across multiple lines).

> Artifacts written to /tmp/test--179460-OJxmqeQ4wxuc
> Compiled successfully using:
   - solc: 0.7.3+commit.9bfce1f6.Emscripten.clang



  TestSupplyChain
    ✓ testBuyerAndSellerAreDifferentActors (1073ms)
    ✓ testItemCanBePutOnSale (1122ms)
    ✓ testUserDoesNotPaysTheRightPrice (1071ms)
    ✓ testUserPaysTheRightPrice (1074ms)
    ✓ testItemCannotBePurchasedTwice (1066ms)
    ✓ testRandomUserCannotShipItem (1084ms)
    ✓ testSellerCanShipItem (1091ms)
    ✓ testCannotShipAnItemThatIsNotSold (1058ms)
    ✓ testNonBuyerCannotSetItemAsReceived (1126ms)
    ✓ testBuyerCanSetItemAsReceived (1104ms)
    ✓ testBuyerCannotReceiveItemNotShipped (1090ms)

  Contract: SupplyChain
    ✓ should add an item with the provided name and price (1048ms)
    ✓ should emit a LogForSale event when an item is added (1027ms)
    ✓ should allow someone to purchase an item and update state accordingly (2052ms)
    ✓ should error when not enough value is sent when purchasing an item (2155ms)
    ✓ should emit LogSold event when and item is purchased (2051ms)
    ✓ should revert when someone that is not the seller tries to call shipItem() (3067ms)
    ✓ should allow the seller to mark the item as shipped (3075ms)
    ✓ should emit a LogShipped event when an item is shipped (3075ms)
    ✓ should allow the buyer to mark the item as received (4101ms)
    ✓ should revert if an address other than the buyer calls receiveItem() (4059ms)
    ✓ should emit a LogReceived event when an item is received (4054ms)


  22 passing (1m)

</details>
