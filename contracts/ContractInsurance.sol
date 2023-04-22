// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract CryptoWalletInsuranceFactory {
    address immutable owner;
    address[] customers;
    mapping(address => address) public customerToContract;
    mapping(address => address) public contractToCustomer;
    mapping(uint8 => uint8) public plans;

    constructor() payable {
        require(msg.value >= 1 ether);
        owner = msg.sender;
        plans[1] = 1;
        plans[2] = 5;
        plans[3] = 10;
    }

    receive() external payable {}

    function withdraw(uint256 amount) public payable {
        require(msg.sender == owner);
        require(address(this).balance >= amount);
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }

    function getCustomers() public view returns (address[] memory) {
        return customers;
    }

    function getCustomerToContract(address customerAddress) public view returns (address) {
        return customerToContract[customerAddress];
    }

    function getInsurance(uint8 plan, address contractAddress, uint256 timePeriod) public payable {
        require(customerToContract[msg.sender] == address(0));
        uint256 amountInsured = contractAddress.balance;
        uint8 _plan = plans[plan];
        require(_plan != 0, "Invalid Plan");
        require(msg.value == (amountInsured * _plan * timePeriod) / 100, "Not send Insurance Amount");
        address insuranceContract = address(
            new CryptoWalletInsurance(
                _plan,
                contractAddress,
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

    function claimInsurance() public payable {
        // Great Way to stop anyone to call this function by using mapping of contract=>customer
        require(contractToCustomer[msg.sender] != address(0));

        CryptoWalletInsurance instance = CryptoWalletInsurance(payable(msg.sender));
        uint256 _claimAmount = instance.getClaimAmount();
        require(_claimAmount != 0, "Claim Amount Should not be 0");
        require(_claimAmount < address(this).balance, "Not enough Funds in Contract");
        (bool sent,) = msg.sender.call{value: _claimAmount}("");
        require(sent, "Transaction was not successsful");
    }
}

contract CryptoWalletInsurance {
    address public immutable owner;
    address public immutable contractAddress;
    uint256 public immutable plan;
    bool public claimed;
    uint256 public immutable amountInsured;
    uint256 public immutable validity;
    uint256 public claimAmount;

    address private immutable factory;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    constructor(
        uint256 _plan,
        address _contractAddress,
        address _owner,
        uint256 _amountInsured,
        uint256 _validity,
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
        require(contractAddress.balance < amountInsured, "There is no change in Balance");
        require(validity > block.timestamp, "Oops your Insurance Expired");
        require(!claimed);
        uint256 hackedAmount = (amountInsured - contractAddress.balance);
        uint256 maximumClaimableAmmount = (amountInsured * plan) / 10;
        if (hackedAmount < maximumClaimableAmmount) {
            claimAmount = hackedAmount;
        } else {
            claimAmount = maximumClaimableAmmount;
        }
    }

    function claim() public onlyOwner {
        require(!claimed, "Already Claimed Reward");
        verifyInsurance();
        claimed = true;
        (bool success,) = factory.call(abi.encodeWithSignature("claimInsurance()"));
        require(success, "Transaction Failed in claim");
    }

    function getClaimAmount() public view returns (uint256) {
        return claimAmount;
    }

    receive() external payable {}

    function withdrawClaim() public payable onlyOwner {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Failed Transaction");
    }
}
