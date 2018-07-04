pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";


contract TestSupplyChain {
    uint public initialBalance = 1 ether;
    SupplyChain public chain;
    Proxy public sellGuy;
    Proxy public buyGuy;

    string itemName = "Gem";
    uint   itemPrice = 3;

    function() public payable {}

    function beforeEach() public
    {
        chain = new SupplyChain();
        sellGuy = new Proxy(chain);
        buyGuy = new Proxy(chain);
        sellGuy.sell(itemName, itemPrice);
    }

    // Test for failing conditions in this contracts
    // test that every modifier is working
    function testItemCanBePutOnSale() public {

        uint expectedState = 0; // 0: Sale
        uint expectedSku = 0;
        address expectedBuyer = address(0);
        address expectedSeller = address(sellGuy);

        string memory name;
        uint sku;
        uint price;
        uint state;
        address seller;
        address buyer;

        ( name, sku, price, state, seller, buyer) = chain.fetchItem(expectedSku);

        Assert.equal(sku, expectedSku, "Item sku is correct");
        Assert.equal(name, itemName, "Item is named correctly");
        Assert.equal(price, itemPrice, "Item price correctly");
        Assert.equal(state, expectedState, "Item State is `For sale`");
        Assert.equal(buyer, expectedBuyer, "Item buyer is 0x0");
        Assert.equal(seller, expectedSeller, "Item seller is the seller`");
    }


    function validateCurrentSkuState(uint _expectedSku, uint _expectedState)
        public
        returns (bool)
    {
        string memory name;
        uint sku;
        uint price;
        uint state;
        address seller;
        address buyer;

        ( name, sku, price, state, seller, buyer) = chain.fetchItem(_expectedSku);
        return state == _expectedState;
    }

    // buyItem
    // test for failure if user does not send enough funds
    function testUserDoesNotPaysTheRightPrice() public {
        uint sku = 0;
        uint offer = itemPrice - 1; // low ball price

        bool result = buyGuy.buy(sku, offer);
        Assert.isFalse(result, "under Paid for item");

        // Verify state is For Sale
        uint expectedState = 0; // For Sale
        Assert.isTrue(validateCurrentSkuState(sku, expectedState), "Item should be `for sale`");
    }

    // buyItem
    // test for purchasing an item that is not for Sale
    function testUserPaysTheRightPrice() public {
        uint sku = 0;
        uint offer = itemPrice + 1; // exceed price

        // solhint-disable-next-line
        bool result = buyGuy.buy(sku, offer);
        Assert.isTrue(result, "Paid the correct price...");

        // Verify state is Sold
        uint expectedState = 1; // Sold
        Assert.isTrue(validateCurrentSkuState(sku, expectedState), "Item should be `Sold`");
    }

    // shipItem
    // Non seller cannot ship
    function _testDoesNotShipWhenCallerNotSeller() public {
        uint sku = 0;

        // Purchase item
        uint offer = itemPrice + 1; // exceed price

        // solhint-disable-next-line
        address(chain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));

        // Use the proxy contract address as msg.sender
        // todo: what's the difference in using callcode?
        bool result = address(buyGuy).delegatecall(abi.encodeWithSignature("ship(uint256)", sku));
        Assert.isFalse(result, "Non seller cannot ship");

        // Verify state remains Sold
        uint expectedState = 1; // Sold
        Assert.isTrue(validateCurrentSkuState(sku, expectedState), "Item should be `Sold`");
    }

    // shipItem
    // only seller can ship
    function _testShipWhenCalledBySeller() public {
        uint sku = 0;

        // Purchase item
        uint offer = itemPrice + 1; // exceed price

        // solhint-disable-next-line
        address(chain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));

        // Try to ship item
        bool result = address(chain).call(abi.encodeWithSignature("shipItem(uint256)", sku));
        Assert.isTrue(result, "Only seller can ship");

        // Verify state is Shipped
        uint expectedState = 2; // Shipped
        Assert.isTrue(validateCurrentSkuState(sku, expectedState), "Item is `Shipped`");
    }

    // shipItem
    // test for trying to ship an item that is not marked Sold
    function _testCannotShipAnItemThatIsNotSold() public {
        uint sku = 0;
        // Note: item starts in forSale state

        // Try to ship item
        bool result = address(chain).call(abi.encodeWithSignature("shipItem(uint256)", sku));
        Assert.isFalse(result, "Cannot ship item not sold.");

        // Verify state is For Sale
        uint expectedState = 0; // For Sale
        Assert.isTrue(validateCurrentSkuState(sku, expectedState), "Item should be `for sale`");
    }

    // receiveItem
    // test calling the function from an address that is not the buyer
    function _testFailsToSetReceiveWhenInvokedBySomeoneNotTheBuyer() public {
        uint sku = 0;
        bool result;

        // Purchase item
        uint offer = itemPrice + 1; // exceed price

        // Use the proxy contract address as msg.sender
        // todo: what's the difference in using callcode?
        result = address(buyGuy).delegatecall(abi.encodeWithSignature("buy(uint256)", sku, offer));
        Assert.isFalse(result, "Non seller cannot ship");

        chain.shipItem(sku);

        // Try to receive item
        result = address(chain).call(abi.encodeWithSignature("receiveItem(uint256)", sku));
        Assert.isFalse(result, "Only buyer should set receive");

        // Verify state is Shipped
        uint expectedState = 2; // Shipped
        Assert.isTrue(validateCurrentSkuState(sku, expectedState), "Item is `Shipped`");
    }


    // receiveItem
    // test calling the function on an item not marked Shipped

}


// Proxy object to act as buyer and seller
//
contract Proxy {
    address public target;

    function() public payable {}

    constructor(address _target) public {
        target = _target;
    }

    function sell(string _itemName, uint _itemPrice) public {
        // solhint-disable-next-line
        SupplyChain(target).addItem(_itemName, _itemPrice);
    }

    function buy(uint sku, uint offer)
        public
        returns (bool)
    {
        // solhint-disable-next-line
        return address(target).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));
    }

    function ship(uint sku)
        public
        returns (bool)
    {
        // solhint-disable-next-line
        return address(target).call(abi.encodeWithSignature("shipItem(uint256)", sku));
    }
}
