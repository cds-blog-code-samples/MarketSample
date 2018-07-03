pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";


contract TestSupplyChain {
    uint public initialBalance = 1 ether;
    SupplyChain public chain;

    string itemName = "Gem";
    uint   itemPrice = 3;

    function() public payable {}

    function beforeEach() public
    {
        chain = new SupplyChain();
        chain.addItem(itemName, itemPrice);
    }

    // Test for failing conditions in this contracts
    // test that every modifier is working
    function testItemCanBePutOnSale() public {

        uint expectedState = 0; // 0: Sale
        uint expectedSku = 0;
        address expectedBuyer = address(0);
        address expectedSeller = this;

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
        Assert.equal(seller, expectedSeller, "Item seller is me");
    }

    // buyItem
    // test for failure if user does not send enough funds
    function testUserDoesNotPaysTheRightPrice() public {
        uint sku = 0;
        uint offer = itemPrice - 1; // low ball price

        // solhint-disable-next-line
        bool result = address(chain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));
        Assert.isFalse(result, "under Paid for item");
    }

    // buyItem
    // test for purchasing an item that is not for Sale
    function testUserPaysTheRightPrice() public {
        uint sku = 0;
        uint offer = itemPrice + 1; // exceed price

        // solhint-disable-next-line
        bool result = address(chain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));
        Assert.isTrue(result, "Paid the correct price...");
    }

    // shipItem
    // Non seller cannot ship
    function testDoesNotShipWhenCallerNotSeller() public {
        uint sku = 0;

        // Purchase item
        uint offer = itemPrice + 1; // exceed price

        // solhint-disable-next-line
        address(chain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));

        Proxy proxy = new Proxy(chain);

        // Use the proxy contract address as msg.sender
        // todo: what's the difference in using callcode?
        bool result = address(proxy).delegatecall(abi.encodeWithSignature("ship(uint256)", sku));
        Assert.isFalse(result, "Non seller cannot ship");
    }

    // shipItem
    // only seller can ship
    function testShipWhenCalledBySeller() public {
        uint expectedSku = 0;

        // Purchase item
        uint offer = itemPrice + 1; // exceed price

        // solhint-disable-next-line
        address(chain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));

        // try to ship item
        bool result = address(chain).call(abi.encodeWithSignature("shipItem(uint256)", expectedSku));
        Assert.isTrue(result, "Only seller can ship");

        // verify state is Shipped
        uint expectedState = 2; // 2: Shipped

        string memory name;
        uint sku;
        uint price;
        uint state;
        address seller;
        address buyer;

        ( name, sku, price, state, seller, buyer) = chain.fetchItem(expectedSku);
        Assert.equal(state, expectedState, "Item State is `Shipped`");
    }

    // shipItem
    // test for trying to ship an item that is not marked Sold
    function testCannotShipAnItemThatIsNotSold() public {
        uint expectedSku = 0;

        // item is in forSale state

        // try to ship item
        bool result = address(chain).call(abi.encodeWithSignature("shipItem(uint256)", expectedSku));
        Assert.isFalse(result, "Cannot ship item not sold.");

        // verify state is Shipped
        uint expectedState = 0; // 2: ForSale

        string memory name;
        uint sku;
        uint price;
        uint state;
        address seller;
        address buyer;

        ( name, sku, price, state, seller, buyer) = chain.fetchItem(expectedSku);
        Assert.equal(state, expectedState, "Item State is `For sale`");
    }

    // receiveItem

    // test calling the function from an address that is not the buyer
    // test calling the function on an item not marked Shipped

}


// Proxy object to act as buyer and seller
//
contract Proxy {
    address public target;

    constructor(address _target) public {
        target = _target;
    }

    function ship(uint sku) public {
        SupplyChain(target).shipItem(sku);
    }
}
