//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";


contract FundMetest is Test {
    uint256 number = 1;
    FundMe fundme; 

    address  USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkingConfig();
        fundme = new FundMe(priceFeed);
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public{
        assertEq(fundme.getOwner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public{
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundme.fund();

    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); 
        fundme.fund{value: 10e18}(); 
        uint256 amountFunded  = fundme.getAddressToAmountFunded(USER );
        assertEq(amountFunded, 10e18);

    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
         
        address funder = fundme.getFunder(0);
        assertEq(funder, USER);


    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithDraw() public funded{
            vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(USER);
        fundme.withdraw();


    }

    function testDrawWithSingleFunder() public funded{
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        uint256 gastStart = gasleft();
        vm.txGasPrice(GAS_PRICE);

        vm.prank(fundme.getOwner());
        fundme.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gastStart - gasEnd) * tx.gasprice;

        console.log("gasUsed", gasUsed);


        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
        



    }

    function testWithdrawFromMultipleFunders () public funded{
        uint160 numberOfFunders = 10;
        uint160 startingFundedIndex = 1;

        for(uint160 i = startingFundedIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();


        assert(address(fundme).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundme.getOwner().balance);
        
        

    }

    receive() external payable {}
}
