pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";


contract TestSupplyChain {
    uint public initialBalance = 1 ether;

    SupplyChain public chain;
    Proxy public sellActor;
    Proxy public buyActor;
    Proxy public randomActor;

    // A fragile dependency here.  Would be nice to import this from a contract
    // This has to continuously stay synced with the contract being tested
    //
    enum State { ForSale, Sold, Shipped, Received }

    string itemName = "Gem";
    uint256 itemPrice = 3;
    uint256 itemSku = 0; // the sku will be set to 0

    // allow contract to receive ether
    function() public payable {}

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
        sellActor.sell(itemName, itemPrice);
    }

    function testItemCanBePutOnSale()
        public
    {
        // Verify state is `ForSale`
        uint expectedState = uint256(State.ForSale);
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
        Assert.equal(state, expectedState, "Item State is `For sale`");
        Assert.equal(buyer, expectedBuyer, "Item buyer is 0x0");
        Assert.equal(seller, expectedSeller, "Item seller is the seller`");
    }

    function getItemState(uint256 _expectedSku)
        public constant
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
    // test for failure if user does not send enough funds
    function testUserDoesNotPaysTheRightPrice() public {
        uint offer = itemPrice - 1; // underfund price

        bool result = buyActor.buy(itemSku, offer);
        Assert.isFalse(result, "under Paid for item");

        // Verify state is For Sale
        uint expectedState = uint256(State.ForSale);
        Assert.equal(getItemState(itemSku), expectedState, "Item should be `for sale`");
    }

    // buyItem
    // test for purchasing an item that is not for Sale
    function testUserPaysTheRightPrice() public {
        uint offer = itemPrice + 1; // exceed price

        Assert.notEqual(address(buyActor), address(sellActor), "buyer and seller should be different");
        Assert.equal(address(chain), sellActor.getTarget(), "chain is the target");

        bool result = buyActor.buy(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Verify state is Sold
        uint expectedState = uint256(State.Sold);
        Assert.equal(getItemState(itemSku), expectedState, "Item should be `Sold`");
    }

    // shipItem
    // Non seller cannot ship
    function testRandomUserCannotShipItem() public {

        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.buy(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        result = randomActor.ship(itemSku);
        Assert.isFalse(result, "Non seller cannot ship");

        // Verify state is Sold
        uint expectedState = uint256(State.Sold);
        Assert.equal(getItemState(itemSku), expectedState, "Item should remain `Sold`");
    }

    // shipItem
    // seller can ship
    function testSellerCanShipItem() public {
        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.buy(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        result = sellActor.ship(itemSku);
        Assert.isTrue(result, "seller should be able to ship");

        // Verify state is Shipped
        uint expectedState = uint256(State.Shipped);
        Assert.equal(getItemState(itemSku), expectedState, "Item should remain `Shipped`");
    }

    // shipItem
    // test for trying to ship an item that is not marked Sold
    function testCannotShipAnItemThatIsNotSold() public {
        // Note: item starts in forSale state

        // Try to ship item
        bool result = sellActor.ship(itemSku);
        Assert.isFalse(result, "Cannot ship item not sold.");

        // Verify state is ForSale
        uint expectedState = uint256(State.ForSale);
        Assert.equal(getItemState(itemSku), expectedState, "Item should remain `ForSale`");
    }

    // receiveItem
    // test calling the function from an address that is not the buyer
    function testNonBuyerCannotSetItemAsReceived() public {
        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.buy(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Ship item
        result = sellActor.ship(itemSku);
        Assert.isTrue(result, "Seller can ship item sold.");

        // Try to receive item
        result = randomActor.receive(itemSku);
        Assert.isFalse(result, "Only buyer should set receive");

        // Verify state is Shipped
        uint expectedState = uint256(State.Shipped);
        Assert.equal(getItemState(itemSku), expectedState, "Item should remain `Shipped`");
    }

    // receiveItem
    // test buyer can set item received
    function testBuyerCanSetItemAsReceived() public {
        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.buy(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Ship item
        result = sellActor.ship(itemSku);
        Assert.isTrue(result, "Seller can ship item sold.");

        // Try to receive item
        result = buyActor.receive(itemSku);
        Assert.isTrue(result, "Buyer can set receive");

        // Verify state is Shipped
        uint expectedState = uint256(State.Received);
        Assert.equal(getItemState(itemSku), expectedState, "Item should be `Received`");
    }

    // receiveItem
    // test calling the function on an item not marked Shipped
    function testBuyerCannotReceiveItemNotShipped() public {
        // Purchase item
        uint offer = itemPrice + 1; // exceed price
        bool result = buyActor.buy(itemSku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Try to receive item
        result = buyActor.receive(itemSku);
        Assert.isFalse(result, "Buyer can set receive");

        // Verify state is Shipped
        uint expectedState = uint256(State.Sold);
        Assert.equal(getItemState(itemSku), expectedState, "Item should be `Sold`");
    }
}


// Proxy contract Actors for buying and selling
//
contract Proxy {
    // Todo: can every contract be initialized with ether?
    address public target;

    constructor(address _target) public { target = _target; }

    // Allow contract to receive ether
    function() public payable {}

    function getTarget()
        public constant
        returns (address)
    {
        return target;
    }

    function sell(string _itemName, uint256 _itemPrice)
        public
    {
        SupplyChain(target).addItem(_itemName, _itemPrice);
    }

    function buy(uint256 sku, uint256 offer)
        public
        returns (bool)
    {
        // solhint-disable-next-line
        return address(target).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));
    }

    function ship(uint256 sku)
        public
        returns (bool)
    {
        // solhint-disable-next-line
        return address(target).call(abi.encodeWithSignature("shipItem(uint256)", sku));
    }

    function receive(uint256 sku)
        public
        returns (bool)
    {
        // solhint-disable-next-line
        return address(target).call(abi.encodeWithSignature("receiveItem(uint256)", sku));
    }
}
