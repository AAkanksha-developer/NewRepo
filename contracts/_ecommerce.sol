// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECommerce {
    struct Product {
        uint id;
        address payable seller;
        string name;
        string description;
        uint price;
        bool sold;
    }

    struct Order {
        uint productId;
        address buyer;
        uint price;
        bool shipped;
        bool received;
        bool dispute;
    }

    uint public productCount;
    uint public orderCount;
    mapping(uint => Product) public products;
    mapping(uint => Order) public orders;
    address public admin;

    event ProductListed(uint productId, address seller, string name, uint price);
    event ProductPurchased(uint productId, address buyer, uint orderId);
    event ProductShipped(uint orderId);
    event ProductReceived(uint orderId);
    event DisputeOpened(uint orderId);
    event DisputeResolved(uint orderId, bool favorBuyer);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this function");
        _;
    }

    modifier onlySeller(uint _productId) {
        require(products[_productId].seller == msg.sender, "Only seller can execute this function");
        _;
    }

    modifier onlyBuyer(uint _orderId) {
        require(orders[_orderId].buyer == msg.sender, "Only buyer can execute this function");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function listProduct(string calldata _name, string calldata _description, uint _price) external {
        require(_price > 0, "Price must be greater than zero");
        productCount++;
        products[productCount] = Product(productCount, payable(msg.sender), _name, _description, _price, false);
        emit ProductListed(productCount, msg.sender, _name, _price);
    }

    function buyProduct(uint _productId) external payable {
        Product storage product = products[_productId];
        require(!product.sold, "Product already sold");
        require(msg.value == product.price, "Incorrect price");

        orderCount++;
        orders[orderCount] = Order(_productId, msg.sender, msg.value, false, false, false);
        product.sold = true;

        emit ProductPurchased(_productId, msg.sender, orderCount);
    }

    function shipProduct(uint _orderId) external onlySeller(orders[_orderId].productId) {
        Order storage order = orders[_orderId];
        require(!order.shipped, "Product already shipped");

        order.shipped = true;
        emit ProductShipped(_orderId);
    }

    function receiveProduct(uint _orderId) external onlyBuyer(_orderId) {
        Order storage order = orders[_orderId];
        require(order.shipped, "Product not shipped yet");
        require(!order.received, "Product already received");

        order.received = true;
        products[order.productId].seller.transfer(order.price);

        emit ProductReceived(_orderId);
    }

    function openDispute(uint _orderId) external onlyBuyer(_orderId) {
        Order storage order = orders[_orderId];
        require(order.shipped, "Product not shipped yet");
        require(!order.received, "Product already received");

        order.dispute = true;
        emit DisputeOpened(_orderId);
    }

    function resolveDispute(uint _orderId, bool _favorBuyer) external onlyAdmin {
        Order storage order = orders[_orderId];
        require(order.dispute, "No dispute for this order");

        order.dispute = false;

        if (_favorBuyer) {
            payable(order.buyer).transfer(order.price);
        } else {
            products[order.productId].seller.transfer(order.price);
        }

        emit DisputeResolved(_orderId, _favorBuyer);
    }
}
