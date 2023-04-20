import "hardhat/console.sol";

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract CryptoWalletInsuranceFactory {
    address immutable owner;
    address[] customers;
    mapping(address => address) public customerToContract;
    mapping(address => address) public contractToCustomer;
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

    function getCustomerToContract(
        address customerAddress
    ) public view returns (address) {
        return customerToContract[customerAddress];
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
                _plan,
                _contractAddress,
                msg.sender,
                amountInsured,
                timePeriod,
                (address(this))
            )
        );
        customerToContract[msg.sender] = insuranceContract;
        contractToCustomer[insuranceContract] = msg.sender;
        customers.push(msg.sender);
    }

    //Check for reentrancy
    function claimInsurance() public payable {
        console.log("COntract in");
        console.log(msg.sender);
        // Great Way to stop anyone to call this function by using mapping of contract=>customer
        require(contractToCustomer[msg.sender] != address(0));

        CryptoWalletInsurance instance = CryptoWalletInsurance(
            payable(msg.sender)
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

    function verifyInsurance() public onlyOwner {
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

        console.log("Claim Acount");
        console.log(claimAmount);
        console.log(address(this));

        (bool success, ) = factory.call(
            abi.encodeWithSignature("claimInsurance()")
        );
        require(success, "Transaction Failed in claim");
        claimed = true;
    }

    function getClaimAmount() public view returns (uint) {
        return claimAmount;
    }

    receive() external payable {}

    function withdrawClaim() public payable onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed Transaction");
    }
}
