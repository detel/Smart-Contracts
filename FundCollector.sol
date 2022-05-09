// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// Collects the funds for the owner with minimum acceptable USD($) amount from each funder.
contract FundCollector {
    event Fund(address indexed funder, uint amount);
    event WithDraw(address owner, uint amount);

    // Onwer of the contract, will recieve all the funds.
    address public owner;
    uint256 minimumUSD;
    address[] public funders;
    mapping(address => uint256) public funderToAmountFunded;
    uint public endAt;
    
    // The account deploying the contract will get the funds.
    constructor(uint _minimumUSD) public {
        owner = msg.sender;
        minimumUSD = _minimumUSD;
        endAt = block.timestamp + 7 days;
    }

    // Used to fund a specific value with minimum USD condition.
    function fund() public payable {
        require(block.timestamp < endAt, "Fund collector has expired.");
        require(getUSDValue(msg.value) >= minimumUSD, "Amount less than the minimum accepted USD amount.");
        funders.push(msg.sender);
        funderToAmountFunded[msg.sender] += msg.value;

        emit Fund(msg.sender, msg.value);
    }

    function getUSDValue(uint256 eth) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData(); // has 8 decimals
        return (uint256(answer) * eth) / 10**10;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    // Owner can withdraw the funds as and when required.
    function withdraw() payable onlyOwner public {
        uint256 withdrawAmount;
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            withdrawAmount += funderToAmountFunded[funder];
            funderToAmountFunded[funder] = 0;
        }
        msg.sender.transfer(withdrawAmount);

        funders = new address[](0);
        
        emit WithDraw(msg.sender, withdrawAmount);
    }
}
