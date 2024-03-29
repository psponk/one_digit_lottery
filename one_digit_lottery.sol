// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public owner;
    uint256 public depositAmount = 3 ether;
    uint256 public commitAmount = 1 ether;
    uint256 public revealTime1; // T1
    uint256 public revealTime2; // T2
    uint8 public winningNumber;
    uint256 public totalPlayers;
    mapping(address => uint8) public playerNumber;
    mapping(uint8 => address) public winners;
    bool public revealed;

    event Deposit(address indexed _from, uint256 _value);
    event Commit(address indexed _from, uint8 _number);
    event Withdraw(address indexed _to, uint256 _value);
    event Winner(address indexed _winner, uint8 _number);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier canPlay() {
        require(!revealed, "Winning number has been revealed");
        require(totalPlayers < 5, "Maximum players reached");
        require(playerNumber[msg.sender] == 0, "You have already played");
        _;
    }

    modifier canReveal() {
        require(block.timestamp >= revealTime1, "Too early to reveal");
        require(!revealed, "Winning number has been revealed");
        _;
    }

    modifier canWithdraw() {
        require(revealed && (block.timestamp >= revealTime2 || totalPlayers == 5), "Cannot withdraw at this time");
        require(playerNumber[msg.sender] != 0, "You have not played");
        _;
    }

    constructor(uint256 _revealTime1, uint256 _revealTime2) {
        owner = msg.sender;
        revealTime1 = _revealTime1;
        revealTime2 = _revealTime2;
    }

    receive() external payable {
        require(msg.value == depositAmount, "Incorrect deposit amount");
        emit Deposit(msg.sender, msg.value);
    }

    function commit(uint8 _number) external payable canPlay {
        require(msg.value == commitAmount, "Incorrect commit amount");
        require(_number <= 4, "Invalid number");
        totalPlayers++;
        playerNumber[msg.sender] = _number;
        emit Commit(msg.sender, _number);
    }

    function reveal(uint8 _winningNumber) external onlyOwner canReveal {
        require(_winningNumber <= 4, "Invalid winning number");
        winningNumber = _winningNumber;
        revealed = true;
        uint8 index = 0;
        for (uint8 i = 1; i <= 5; i++) {
            if (playerNumber[winners[i]] == winningNumber) {
                index = i;
                break;
            }
        }
        if (index > 0) {
            payable(winners[index]).transfer(depositAmount);
            emit Winner(winners[index], winningNumber);
        }
    }

function deposit() external payable {
    require(msg.value == 1 ether, "Incorrect deposit amount");
    emit Deposit(msg.sender, msg.value);
}


    function withdraw() external canWithdraw {
        uint256 amount = commitAmount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function ownerWithdraw() external onlyOwner {
        require(!revealed, "Winning number has been revealed");
        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);
        emit Withdraw(owner, amount);
    }
}
