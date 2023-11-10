// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getEthPriceInUsd(AggregatorV3Interface priceFeed) internal view returns (uint256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price) * 1e10;
  }

  function convertEthToUsd(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
    uint256 ethPrice = getEthPriceInUsd(priceFeed);
    uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
    return ethAmountInUsd;
  }
}
