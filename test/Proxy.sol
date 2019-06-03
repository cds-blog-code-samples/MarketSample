pragma solidity >= 0.5.0 < 0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";


// Proxy contract Actors for buying and selling
//
contract Proxy {
    SupplyChain public target;

    constructor(SupplyChain _target) public { target = _target; }

    // Allow contract to receive ether
    function() external payable {}

    function getTarget()
        public view
        returns (SupplyChain)
    {
        return target;
    }

    function sell(string memory itemName, uint256 itemPrice)
        public
    {
        target.addItem(itemName, itemPrice);
    }

    function buy(uint256 sku, uint256 offer)
        public
        returns (bool)
    {
        (bool success, ) = address(target).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));
        return success;
    }

    function ship(uint256 sku)
        public
        returns (bool)
    {
        (bool success, ) = address(target).call(abi.encodeWithSignature("shipItem(uint256)", sku));
        return success;
    }

    function receive(uint256 sku)
        public
        returns (bool)
    {
        (bool success, ) = address(target).call(abi.encodeWithSignature("receiveItem(uint256)", sku));
        return success;
    }
}
