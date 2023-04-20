// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

contract Storage {
    uint256 number;
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function store() public payable {
        number += msg.value;
    }

    function withdraw(uint amount) public payable {
        require(msg.sender == owner);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}
