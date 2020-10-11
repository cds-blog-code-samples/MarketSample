// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChainState.sol";
import "../contracts/SupplyChain.sol";
import "./Proxy.sol";


contract TestSupplyChain is SupplyChainState {
    uint public initialBalance = 1 ether;

    SupplyChain public chain;
    Proxy public sellActor;
    Proxy public buyActor;
    Proxy public randomActor;

    string itemName = "Gem";
    uint256 itemPrice = 3;
    uint256 itemSku = 0; // the sku will be set to 0

    // allow contract to receive ether
    function() external payable {}

    function beforeEach() public
    {
        // Contract to test
        chain = new SupplyChain();

        // Sell transaction actor
        sellActor = new Proxy(chain);

        // Buy transaction actor
        buyActor = new Proxy(chain);

        // Random transaction actor, neither buyer nor seller
        randomActor = new Proxy(chain);

        // Seed buyer with some funds
        // Note: these values are in wei
        uint256 seedValue = itemPrice + 1;
        address(buyActor).transfer(seedValue);

        // Seed known item to set contract to `for-sale`
        sellActor.placeItemForSale(itemName, itemPrice);
    }

    function testBuyerAndSellerAreDifferentActors()
        public
    {
        Assert.notEqual(address(buyActor), address(sellActor), "buyer and seller should be different");
        Assert.equal(address(chain), address(sellActor.getTarget()), "chain is the target");
    }

    function testItemCanBePutOnSale()
        public
    {
        // Verify state is `ForSale`
        address expectedBuyer = address(0);
        address expectedSeller = address(sellActor);

        string memory name;
        uint sku;
        uint price;
        uint state;
        address seller;
        address buyer;

        ( name, sku, price, state, seller, buyer) = chain.fetchItem(itemSku);

        Assert.equal(sku, itemSku, "Item sku is correct");
        Assert.equal(name, itemName, "Item is named correctly");
        Assert.equal(price, itemPrice, "Item price correctly");
        Assert.equal(state, uint256(State.ForSale), "Item State is `For sale`");
        Assert.equal(buyer, expectedBuyer, "Item buyer is 0x0");
        Assert.equal(seller, expectedSeller, "Item seller is the seller`");
    }

    function getItemState(uint256 _expectedSku)
        public view
        returns (uint256)
    {
        string memory name;
        uint sku;
        uint price;
        uint state;
        address seller;
        address buyer;

        ( name, sku, price, state, seller, buyer) = chain.fetchItem(_expectedSku);
        return state;
    }

    // buyItem
    // test buyer tries to underpay
    function testUserDoesNotPaysTheRightPrice() public {
        uint offer = itemPrice - 1; // underfund price

        bool result = buyActor.purchaseItem(itemSku, offer);
        Assert.isFalse(result, "under Paid for item");

        // Verify state is For Sale
        Assert.equal(getItemState(itemSku), uint256(State.ForSale), "Item should be `ForSale`");
    }

    // buyItem
    // test buyer pays the ask price
    function testUserPaysTheRightPrice() public {
        uint offer = itemPrice + 1; // exceed price

        bool result = buyActor.purchaseItem(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Verify state is Sold
        Assert.equal(getItemState(itemSku), uint256(State.Sold), "Item should be `Sold`");
    }

    // buyItem
    // test item cannot be purchased twice
    function testItemCannotBePurchasedTwice() public {
        uint offer = itemPrice + 1; // exceed price

        bool result = buyActor.purchaseItem(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        result = buyActor.purchaseItem(itemSku, offer);
        Assert.isFalse(result, "Should not be able to double buy an item");

        // Verify state is Sold
        Assert.equal(getItemState(itemSku), uint256(State.Sold), "Item should be `Sold`");
    }
    // shipItem
    // test some random user cannot Ship item
    function testRandomUserCannotShipItem() public {

        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.purchaseItem(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        result = randomActor.shipItem(itemSku);
        Assert.isFalse(result, "Non seller cannot ship");

        // Verify state is Sold
        Assert.equal(getItemState(itemSku), uint256(State.Sold), "Item should remain `Sold`");
    }

    // shipItem
    // test seller can ship item
    function testSellerCanShipItem() public {
        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.purchaseItem(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        result = sellActor.shipItem(itemSku);
        Assert.isTrue(result, "seller should be able to ship");

        // Verify state is Shipped
        Assert.equal(getItemState(itemSku), uint256(State.Shipped), "Item should be `Shipped`");
    }

    // shipItem
    // test that items can't be shipped if they are not sold
    function testCannotShipAnItemThatIsNotSold() public {
        // Note: item starts in forSale state

        // Try to ship item
        bool result = sellActor.shipItem(itemSku);
        Assert.isFalse(result, "Cannot ship item that is `ForSale`.");

        // Verify state is ForSale
        Assert.equal(getItemState(itemSku), uint256(State.ForSale), "Item should remain `ForSale`");
    }

    // receiveItem
    // test some random actor cannot receive item
    function testNonBuyerCannotSetItemAsReceived() public {
        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.purchaseItem(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Ship item
        result = sellActor.shipItem(itemSku);
        Assert.isTrue(result, "Seller can ship item that was sold.");

        // Try to receive item
        result = randomActor.receiveItem(itemSku);
        Assert.isFalse(result, "Only buyer can receive an item");

        // Verify state is Shipped
        Assert.equal(getItemState(itemSku), uint256(State.Shipped), "Item should remain `Shipped`");
    }

    // receiveItem
    // test buyer can receive item
    function testBuyerCanSetItemAsReceived() public {
        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.purchaseItem(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Ship item
        result = sellActor.shipItem(itemSku);
        Assert.isTrue(result, "Seller can ship item that was sold.");

        // Try to receive item
        result = buyActor.receiveItem(itemSku);
        Assert.isTrue(result, "Buyer can set receive");

        // Verify state is Shipped
        Assert.equal(getItemState(itemSku), uint256(State.Received), "Item should be `Received`");
    }

    // receiveItem
    // test a buyer cannot recieve an item not shipped
    function testBuyerCannotReceiveItemNotShipped() public {
        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.purchaseItem(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Try to receive item
        result = buyActor.receiveItem(itemSku);
        Assert.isFalse(result, "Buyer can not receive an item thats `sold`");

        // Verify state is Sold
        Assert.equal(getItemState(itemSku), uint256(State.Sold), "Item should be `Sold`");
    }
}
