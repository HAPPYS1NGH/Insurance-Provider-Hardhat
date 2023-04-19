// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy.js
 */
contract Storage {
    uint256 number;

    function store() public payable {
        number += msg.value;
    }

    function destruct(address payable ad) public payable {
        selfdestruct(ad);
    }

    function withdraw(uint _amount) public payable {
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success);
    }

    /**
     * @dev Return value
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256) {
        return number;
    }
}
