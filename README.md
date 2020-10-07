# Supply Chain example Solidity

## Solidity testing

Use a proxy pattern where the proxy communicates to the test supplyChain
subject on behalf of the test runner. In the diagram below TestSupplyChain is
the test runner and multiple actors can be instanciated to fullfil the test
scenario.


TestSupplyChain

  - receives ether from Truffle in order to run transactions.
  - creates a testChain, buyer, seller and randomPerson proxy then registers an
    item for sale on the subject testChain

Each test will need
  - a testChain (the subject)
  - a buyer
  - a seller
  - an item and its price to be sold


### UML

![UML](./uml.png)

``` plantuml
@startuml
Actor : supplyChainSubject
Actor : bool placeItemForSale(item, price)
Actor : bool purchaseItem(sku, offer)
Actor : bool shipItem(sku)
Actor : bool receiveItem(sku)
note right of Actor
This is a proxy for a buyer, seller or random actor that interracts with the
supplyChain subject.  Each actor has its own <b>address</b>.

You will need to use the <b>call</b> and  <b>abi.encodeWithSignature</b> solidity methods.

        /// Use call.value to invoke `supplyChain.buyItem(sku)` with msg.sender
        /// set to the address of this proxy and value is set to `offer`
        (bool success, ) = address(supplyChain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));
        return success;
end note

TestSupplyChain : Actor buyer
TestSupplyChain : Actor seller
TestSupplyChain : Actor randomPerson
TestSupplyChain : supplyChain

TestSupplyChain : beforeEach() // create and fund actors
TestSupplyChain : testItemCanBePutOnSale()
TestSupplyChain : testUserDoesNotPayTheRightPrice()
TestSupplyChain : testUserPaysCorrectPrice()
TestSupplyChain : testItemCannotBePurchasedTwice()
TestSupplyChain : testRandomUserCannotShipItem()
TestSupplyChain : testSellerCanShipItem()
TestSupplyChain : testCannotShipAnItemThatIsNotSold()
TestSupplyChain : testNonBuyerCannotSetItemAsReceived()
TestSupplyChain : testBuyerCanSetItemAsReceived()
TestSupplyChain : testBuyerCannotReceiveItemNotShipped()
note right of TestSupplyChain
* is the entry point for Truffle test
* receives funds
end note

@enduml

```
