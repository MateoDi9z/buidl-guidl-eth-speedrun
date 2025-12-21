// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    uint256 public deadline = block.timestamp + 72 hours; // deadline

    bool public openForWithdraw = false;

    event Stake(address staker, uint256 amount); // Event definition

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

    mapping(address => uint256) public balances; // Mapeo de address -> balance
    uint256 public constant threshold = 1 ether; // Minimo para stakear

    function stake() public payable notCompleted deadlineNotReached {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public notCompleted deadlineReached {
        require(openForWithdraw == false, "Already open for withdraw");
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{ value: address(this).balance }();
        } else {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public thresholdUnreached notCompleted deadlineReached {
        require(openForWithdraw == true, "Not open for withdraw");

        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }

    // Modifiers
    modifier thresholdUnreached() {
        require(address(this).balance < threshold, "Threshold reached.");
        _;
    }

    modifier deadlineReached() {
        require(block.timestamp >= deadline, "Deadline not reached");
        _;
    }

    modifier deadlineNotReached() {
        require(block.timestamp < deadline, "Deadline reached");
        _;
    }

    modifier notCompleted() {
        require(exampleExternalContract.completed() == false, "Already completed");
        _;
    }
}
