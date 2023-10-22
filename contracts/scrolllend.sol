// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScrollLend {
    address payable public owner;
    uint256 public totalDeposits;
    uint256 public totalBorrowed;
    uint256 public interestRate = 5; // 5% annual interest rate
    uint256 public liquidationThreshold = 120; // 120% collateralization required

    struct Account {
        uint256 balance;
        uint256 borrowed;
        uint256 collateral;
    }

    mapping(address => Account) public accounts;

    constructor() {
        owner = payable(msg.sender); // Make the owner address payable
    }

    function deposit() external payable {
        require(msg.value > 0, "You must deposit some Ether.");
        Account storage userAccount = accounts[msg.sender];
        userAccount.balance += msg.value;
        userAccount.collateral += msg.value;
        totalDeposits += msg.value;
    }

    function borrow(uint256 amount) external {
        Account storage userAccount = accounts[msg.sender];
        uint256 maxBorrow = (userAccount.collateral * liquidationThreshold) / 100 - userAccount.borrowed;
        require(amount > 0 && amount <= maxBorrow, "Invalid borrowing amount.");
        userAccount.balance += amount;
        userAccount.borrowed += amount;
        totalBorrowed += amount;
    }

    function repay() external payable {
        require(msg.value > 0, "You must repay some Ether.");
        Account storage userAccount = accounts[msg.sender];
        uint256 repayAmount = msg.value;
        require(repayAmount > 0 && repayAmount <= userAccount.borrowed, "Invalid repayment amount.");
        uint256 interest = (repayAmount * interestRate) / 100;
        uint256 principal = repayAmount - interest;
        userAccount.balance -= principal;
        userAccount.borrowed -= repayAmount;
        totalBorrowed -= repayAmount;
        // Transfer interest to the owner as a fee.
        owner.transfer(interest);
    }

    function addCollateral() external payable {
        require(msg.value > 0, "You must add some collateral.");
        Account storage userAccount = accounts[msg.sender];
        userAccount.balance += msg.value;
        userAccount.collateral += msg.value;
    }

    function withdrawCollateral(uint256 amount) external {
        Account storage userAccount = accounts[msg.sender];
        require(amount > 0 && amount <= userAccount.collateral, "Invalid collateral withdrawal amount.");
        userAccount.collateral -= amount;
        userAccount.balance -= amount;
    }

    function calculateInterest(address user) public view returns (uint256) {
        return (accounts[user].borrowed * interestRate) / 100;
    }

    function liquidate(address user) external {
        Account storage userAccount = accounts[user];
        require(userAccount.collateral * 100 < userAccount.borrowed * liquidationThreshold, "Account is not eligible for liquidation.");
        uint256 liquidationAmount = userAccount.borrowed + calculateInterest(user);
        require(address(this).balance >= liquidationAmount, "Vault does not have sufficient balance for liquidation.");
        userAccount.balance -= liquidationAmount;
        totalBorrowed -= liquidationAmount;
        payable(msg.sender).transfer(liquidationAmount);
    }
}
