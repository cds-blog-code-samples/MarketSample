pragma solidity >= 0.5.0 < 0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";


/// @title Simulate Roles for testing scenarios
/// @notice Use this Contract to simulate various roles in tests
/// @dev A Proxy can fulfill a Buyer, Seller or random agent
contract Proxy {

    /// the proxied SupplyChain contract
    SupplyChain public supplyChain;

    /// @notice Create a proxy
    /// @param _target the SupplyChain to interact with
    constructor(SupplyChain _target) public { supplyChain = _target; }

    /// Allow contract to receive ether
    function() external payable {}


    /// @notice Retrieve supplyChain contract
    /// @return the supplyChain contract
    function getTarget()
        public view
        returns (SupplyChain)
    {
        return supplyChain;
    }

    /// @notice Place an item for sale
    /// @param itemName short description of item
    /// @param itemPrice price in WEI
    function placeItemForSale(string memory itemName, uint256 itemPrice)
        public
    {
        supplyChain.addItem(itemName, itemPrice);
    }

    /// @notice Purchase an item
    /// @param sku item Sku
    /// @param offer the price you pay
    function purchaseItem(uint256 sku, uint256 offer)
        public
        returns (bool)
    {
        /// Use call.value to invoke `supplyChain.buyItem(sku)` with msg.sender
        /// set to the address of this proxy and value is set to `offer`
        (bool success, ) = address(supplyChain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));
        return success;
    }

    /// @notice Ship an item
    /// @param sku item Sku
    function shipItem(uint256 sku)
        public
        returns (bool)
    {
        /// invoke `supplyChain.shipItem(sku)` with msg.sender set to the address of this proxy
        (bool success, ) = address(supplyChain).call(abi.encodeWithSignature("shipItem(uint256)", sku));
        return success;
    }

    /// @notice Receive an item
    /// @param sku item Sku
    function receiveItem(uint256 sku)
        public
        returns (bool)
    {
        /// invoke `receiveChain.shipItem(sku)` with msg.sender set to the address of this proxy
        (bool success, ) = address(supplyChain).call(abi.encodeWithSignature("receiveItem(uint256)", sku));
        return success;
    }
}
