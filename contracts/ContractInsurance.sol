import "hardhat/console.sol";

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract CryptoWalletInsuranceFactory {
    address immutable owner;
    address[] customers;
    mapping(address => address) public customerToContract;
    mapping(uint8 => uint8) public plans;

    constructor() {
        owner = msg.sender;
        plans[1] = 1;
        plans[2] = 5;
        plans[3] = 10;
    }

    function getCustomers() public view returns (address[] memory) {
        return customers;
    }

    function getInsurance(
        uint8 plan,
        address _contractAddress,
        uint timePeriod
    ) public payable {
        require(customerToContract[msg.sender] == address(0));
        uint256 amountInsured = _contractAddress.balance;
        uint8 _plan = plans[plan];
        require(_plan != 0, "Invalid Plan");
        require(
            msg.value == (amountInsured * _plan * timePeriod) / 100,
            "Not send Insurance Amount"
        );
        address insuranceContract = address(
            new CryptoWalletInsurance(
                plan,
                _contractAddress,
                msg.sender,
                amountInsured,
                timePeriod,
                (address(this))
            )
        );
        customerToContract[msg.sender] = insuranceContract;
        customers.push(msg.sender);
    }

    //Check for reentrancy
    function claimInsurance() public payable {
        require(customerToContract[msg.sender] != address(0));
        CryptoWalletInsurance instance = CryptoWalletInsurance(
            customerToContract[msg.sender]
        );
        uint _claimAmount = instance.getClaimAmount();
        require(_claimAmount != 0, "Claim Amount Should not be 0");
        require(
            _claimAmount < address(this).balance,
            "Not enough Funds in Contract"
        );
        (bool sent, ) = msg.sender.call{value: _claimAmount}("");
        require(sent, "Transaction was not successsful");
    }
}

contract CryptoWalletInsurance {
    address public owner;
    address public contractAddress;
    uint public plan;
    bool public claimed;
    uint public amountInsured;
    uint public validity;
    uint public claimAmount;

    address private immutable factory;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    constructor(
        uint _plan,
        address _contractAddress,
        address _owner,
        uint _amountInsured,
        uint _validity,
        address factoryContract
    ) {
        plan = _plan;
        contractAddress = _contractAddress;
        owner = _owner;
        amountInsured = _amountInsured;
        validity = block.timestamp + _validity * 2629743; //validity in minutes
        factory = factoryContract;
    }

    function verifyInsurance() internal onlyOwner {
        require(
            contractAddress.balance < amountInsured,
            "There is no change in Balance"
        );
        require(validity > block.timestamp, "Oops your Insurance Expired");
        uint hackedAmount = (amountInsured - contractAddress.balance);
        uint maximumClaimableAmmount = (amountInsured * plan) / 10;
        if (hackedAmount < maximumClaimableAmmount) {
            claimAmount = hackedAmount;
        } else {
            claimAmount = maximumClaimableAmmount;
        }
    }

    function claim() public onlyOwner {
        require(!claimed, "Already Claimed Reward");
        verifyInsurance();
        (bool success, ) = factory.call(
            abi.encodeWithSignature("claimInsurance()")
        );
        require(success, "Transaction Failed");
        claimed = true;
    }

    function getClaimAmount() public view returns (uint) {
        return claimAmount;
    }
}
