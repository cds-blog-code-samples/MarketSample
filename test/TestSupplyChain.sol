pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";


contract TestSupplyChain {

    // Test for failing conditions in this contracts
    // test that every modifier is working

    function testItemCanBePutOnSale() public {
        // SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        SupplyChain supplyChain = new SupplyChain();
        supplyChain.addItem("Gem", 108);

        uint forSale = 0;

        (
        string memory name, uint sku, uint price,
        uint state, address seller, address buyer
        )  = supplyChain.fetchItem(0);

        Assert.equal(state, forSale, "Initial item is for sale");
    }

    function testThatUserNeedsEnoughFunds() public {
        SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        supplyChain.addItem("Gem", 108);

        uint sku = 0;
        // bool result = supplyChain.call.value(200).gas(80000 wei)(bytes4(keccak256("buyItem(uint)")), sku);
        bool result = address(supplyChain).call.value(2000)(abi.encodeWithSignature("buyItem(uint)", sku));

        Assert.isFalse(result, "should not be able to purchase item with less funds than required");
    }

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
