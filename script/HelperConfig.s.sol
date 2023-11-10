// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
  // If we're on a local chain, deploy mocks
  // Otherwise, grab the existing address from the live network

  uint8 public constant DECIMALS = 8;
  int256 public constant INITIAL_PRICE = 2000e8;

  NetworkConfig public activeNetworkConfig;

  struct NetworkConfig {
    address priceFeed; // ETH/USD price feed address
  }

  constructor() {
    if (block.chainid == 1) {
      activeNetworkConfig = getMainnetEthConfig();
    } else if (block.chainid == 11155111) {
      activeNetworkConfig = getSepoliaEthConfig();
    } else {
      activeNetworkConfig = getOrCreateAnvilEthConfig();
    }
  }

  function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
  }

  function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
  }

  function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    if (activeNetworkConfig.priceFeed != address(0)) {
      return activeNetworkConfig;
    }

    vm.startBroadcast();
    MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    vm.stopBroadcast();

    return NetworkConfig({priceFeed: address(mockPriceFeed)});
  }
}
