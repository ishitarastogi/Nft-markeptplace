// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC20.sol";


contract NFTMarket  {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds; //Id for each individual item
  Counters.Counter private _itemsSold; // No of items sold

  address payable owner; // Owner is the owner of the contract who makes commission on every transaction
  uint listingPrice= 0.5 ether; //listing price put by seller
  ERC20Token public tokenAddress;// ERC20 Token address for payment method

  constructor(address _tokenAddress) {
      owner = payable(msg.sender);
     tokenAddress = ERC20Token(_tokenAddress);

  }

  struct Items{
      uint itemId; 
      address NFTAddress;
      uint tokenId;
      address payable seller;
      address payable owner;
      uint price;
      bool sold;  
}

mapping(uint => Items) ItemId;

event ItemsCreated (
    uint indexed itemId,
    uint indexed tokenId,
    address NFTAddress,
    address  seller,
    address  owner,
    uint price,
    bool sold  
);

// 2 function
// 1st is for creating a market item and putting it for a sale
//creating a market sale for buy and selling an item bw parties

 function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable  {
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();
  
    ItemId[itemId] =  Items(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      false
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit ItemsCreated(
      itemId,
       tokenId,
      nftContract,
     
      msg.sender,
      address(0),
      price,
      false
    );
  }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
  function createMarketSale(
    address nftContract,
    uint256 itemId
    ) public payable  {
    uint price = ItemId[itemId].price;
    uint tokenId = ItemId[itemId].tokenId;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");
    tokenAddress.transfer( ItemId[itemId].seller, msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    ItemId[itemId].owner = payable(msg.sender);
    ItemId[itemId].sold = true;
    _itemsSold.increment();
    payable(owner).transfer(listingPrice);
  }
  
   function fetchMarketItems() public view returns (Items[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    Items[] memory items = new Items[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (ItemId[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        Items storage currentItem = ItemId[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }
  
    function fetchMyNFTs() public view returns (Items[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (ItemId[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    Items[] memory items = new Items[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (ItemId[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        Items storage currentItem = ItemId[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }
  
   /* Returns only items a user has created */
  function fetchItemsCreated() public view returns (Items[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (ItemId[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    Items[] memory items = new Items[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (ItemId[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        Items storage currentItem = ItemId[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }


}
