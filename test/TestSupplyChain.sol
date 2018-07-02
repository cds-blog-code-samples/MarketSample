pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";


contract ThrowProxy {
    address public target;
    bytes data;
    uint value;

    constructor(address _target, uint _value) public {
        target = _target;
        value = _value;
    }

    // prime the data using the fallback function.
    function() public {
        data = msg.data;
    }

    function execute() public payable returns (bool) {
        return target.call.value(value)(data);
    }
}


contract TestSupplyChain {
    function initializeContract()
    public
    returns (SupplyChain)
    {
        return new SupplyChain();
    }

    function putItemForSale()
    public
    returns (SupplyChain)
    {
        SupplyChain chain = initializeContract();
        chain.addItem("Gem", 108);
        return chain;
    }

    // Test for failing conditions in this contracts
    // test that every modifier is working
    function testItemCanBePutOnSale() public {
        SupplyChain chain = putItemForSale();

        uint expectedState = 0; // 0: Sale
        uint expectedPrice = 108;
        uint expectedSku = 0;
        string memory expectedName = "Gem";
        address expectedBuyer = address(0);
        address expectedSeller = address(msg.sender);

        (
        string memory name, uint sku, uint price, uint state, address seller, address buyer
        )  = chain.fetchItem(0);

        Assert.equal(state, expectedState, "Item State is `For sale`");
        Assert.equal(name, expectedName, "Item is named correctly");
        Assert.equal(sku, expectedSku, "Item sku is 0");
        Assert.equal(price, expectedPrice, "Item sku is 0");
        Assert.equal(buyer, expectedBuyer, "Item buyer is 0x0");

        // Todo: how to test for expected seller?
        // Which account is used by the test runner?
        // Assert.equal(seller, expectedSeller, "Item seller is me");
    }

    function testUserPaysTheRightPrice() public {
        SupplyChain chain = putItemForSale();
        ThrowProxy proxy = new ThrowProxy(address(chain), 2009);
        uint sku = 0;
        SupplyChain(address(proxy)).buyItem(sku);
        bool result = proxy.execute.gas(5100000 wei)();
        // bool result = address(chain).call.value(2000)(abi.encodeWithSignature("buyItem(uint)", sku));
        Assert.isFalse(result, "should not be able to purchase item with less funds than required");
    }

// function testUserPaysTheRightPrice() public {
        // SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        // supplyChain.addItem("Gem", 108);
        // uint sku = 0;
        // bool result = address(supplyChain).call.value(2000)(abi.encodeWithSignature("buyItem(uint)", sku));
        // Assert.isFalse(result, "should not be able to purchase item with less funds than required");
    // }

    // function testUserPaysTheRightPrice() public {
        // SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        // supplyChain.addItem("Gem", 108);
        // uint sku = 0;
        // bool result = address(supplyChain).call.value(2000)(abi.encodeWithSignature("buyItem(uint)", sku));
        // Assert.isFalse(result, "should not be able to purchase item with less funds than required");
    // }

    // buyItem

    // test for failure if user does not send enough funds
    // test for purchasing an item that is not for Sale


    // shipItem

    // test for calls that are made by not the seller
    // test for trying to ship an item that is not marked Sold

    // receiveItem

    // test calling the function from an address that is not the buyer
    // test calling the function on an item not marked Shipped
}
