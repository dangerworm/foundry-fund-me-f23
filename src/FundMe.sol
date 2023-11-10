// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  // State variables
  uint256 public constant MINIMUM_USD = 5e18;
  address private immutable i_owner;
  address[] private s_funders;
  mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
  AggregatorV3Interface private s_priceFeed;

  // Events (we have none!)

  // Modifiers
  modifier onlyOwner() {
    if (msg.sender != i_owner) {
      revert FundMe__NotOwner();
    }
    _;
  }

  // Functions
  // Order: constructor, receive, fallback, external, public, internal, private, view / pure (getters)

  constructor(address _priceFeed) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(_priceFeed);
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  function fund() public payable {
    require(msg.value.convertEthToUsd(s_priceFeed) >= MINIMUM_USD, "Didn't send enough (min 5 GBP)");

    s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] + msg.value;
    s_funders.push(msg.sender);
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }

    s_funders = new address[](0);

    /*
      // Transfer - not recommended
      payable(msg.sender).transfer(address(this).balance);

      // Send - not recommended
      bool sendSuccess = payable(msg.sender).send(address(this).balance);
      require(sendSuccess, "Sending failed");
    */

    // Call - current best practice
    (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(callSuccess, "Call failed");
  }

  function cheaperWithdraw() public onlyOwner {
    uint256 fundersLength = s_funders.length;

    for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }

    s_funders = new address[](0);
    (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
    require(callSuccess, "Call failed");
  }

  function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
    return s_addressToAmountFunded[fundingAddress];
  }

  function getVersion() external view returns (uint256) {
    return s_priceFeed.version();
  }

  function getFunder(uint256 index) external view returns (address) {
    return s_funders[index];
  }

  function getPriceFeed() external view returns (AggregatorV3Interface) {
    return s_priceFeed;
  }

  function getOwner() external view returns (address) {
    return i_owner;
  }
}
