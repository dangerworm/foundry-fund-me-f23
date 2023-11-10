// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
  FundMe fundMe;

  address USER;
  uint256 constant GAS_PRICE = 1;
  uint256 constant MINIMUM_USD = 5e18;
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 10 ether;

  modifier funded() {
    vm.prank(USER); // The next Tx will be sent by USER
    fundMe.fund{value: SEND_VALUE}();
    _;
  }

  function setUp() external {
    USER = makeAddr("test-user");
    deal(USER, STARTING_BALANCE);

    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
  }

  function testMinimumUsdIs5() public {
    assertEq(fundMe.MINIMUM_USD(), MINIMUM_USD);
  }

  function testOwnerIsMessageSender() public {
    assertEq(fundMe.getOwner(), msg.sender);
  }

  function testPriceFeedVersionIsAccurate() public {
    uint256 version = fundMe.getVersion();

    assertEq(version, 4);
  }

  function testFundFailsWithoutEnoughEth() public {
    vm.expectRevert();
    fundMe.fund();
  }

  function testFundUpdatesFundedDataStructure() public funded {
    uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
    assertEq(amountFunded, SEND_VALUE);
  }

  function testAddsFunderToArrayOfFunders() public funded {
    address funder = fundMe.getFunder(0);
    assertEq(funder, USER);
  }

  function testOnlyOwnerCanWithdraw() public funded {
    vm.expectRevert();
    vm.prank(USER); // The next Tx will be sent by USER
    fundMe.withdraw();
  }

  function testWithdrawFromASingleFunder() public funded {
    uint256 startingFundMeContractBalance = address(fundMe).balance;
    uint256 startingOwnerBalance = fundMe.getOwner().balance;

    uint256 gasStart = gasleft();
    vm.txGasPrice(GAS_PRICE);
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();
    uint256 gasEnd = gasleft();
    uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
    console.log(gasUsed);

    assertEq(address(fundMe).balance, 0);
    assertEq(startingOwnerBalance + startingFundMeContractBalance, fundMe.getOwner().balance);
  }

  function testWithdrawFromMultipleFunders() public funded {
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;

    for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
      hoax(address(i), SEND_VALUE);
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingFundMeContractBalance = address(fundMe).balance;
    uint256 startingOwnerBalance = fundMe.getOwner().balance;

    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();

    assertEq(address(fundMe).balance, 0);
    assertEq(startingOwnerBalance + startingFundMeContractBalance, fundMe.getOwner().balance);
  }

  function testOnlyOwnerCanWithdrawCheaper() public funded {
    vm.expectRevert();
    vm.prank(USER); // The next Tx will be sent by USER
    fundMe.cheaperWithdraw();
  }

  function testWithdrawFromASingleFunderCheaper() public funded {
    uint256 startingFundMeContractBalance = address(fundMe).balance;
    uint256 startingOwnerBalance = fundMe.getOwner().balance;

    vm.prank(fundMe.getOwner());
    fundMe.cheaperWithdraw();

    assertEq(address(fundMe).balance, 0);
    assertEq(startingOwnerBalance + startingFundMeContractBalance, fundMe.getOwner().balance);
  }

  function testWithdrawFromMultipleFundersCheaper() public funded {
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;

    for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
      hoax(address(i), SEND_VALUE);
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingFundMeContractBalance = address(fundMe).balance;
    uint256 startingOwnerBalance = fundMe.getOwner().balance;

    vm.startPrank(fundMe.getOwner());
    fundMe.cheaperWithdraw();
    vm.stopPrank();

    assertEq(address(fundMe).balance, 0);
    assertEq(startingOwnerBalance + startingFundMeContractBalance, fundMe.getOwner().balance);
  }
}
