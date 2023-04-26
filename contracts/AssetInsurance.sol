// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IERC20.sol";

pragma solidity 0.8.18;

contract CryptoAssetInsuranceFactory {
    address immutable owner;
    address immutable ethToUsd;
    address[] customers;
    mapping(address => address) public customerToContract;
    mapping(address => address) public contractToCustomer;
    mapping(uint8 => uint8) public plans;

    constructor(address _ethToUsd) payable {
        require(msg.value >= 1 ether);
        require(_ethToUsd != address(0));
        owner = msg.sender;
        plans[1] = 1;
        plans[2] = 5;
        plans[3] = 10;
        ethToUsd = _ethToUsd;
    }

    function getOwner() public view returns (address) {
        return owner;
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

    function getTokenBalance(address tokenAddress, address accountAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(accountAddress);
    }

    function getFeedValueOfAsset(address _oracleAddress) public view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(_oracleAddress);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = priceConsumer.latestRoundData();
        return uint256(price);
    }

    function getUsdToWei() public view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(ethToUsd);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = priceConsumer.latestRoundData();
        return uint256((10 ** 26) / price);
    }

    function calculateDepositMoney(
        uint256 _tokens,
        uint256 _plan,
        uint256 _priceAtInsurance,
        uint256 _decimals,
        uint256 _timePeriod
    ) public view returns (uint256) {
        // console.log("Calculate _tokens _plan, _priceAtInsurance,_decimals _timePeriod");
        // console.log(_tokens);
        // console.log(_plan);
        // console.log(_priceAtInsurance);
        // console.log(_decimals);
        // console.log(_timePeriod);
        //decimals left
        uint256 conversionRate = getUsdToWei();
        uint256 pricePayable =
            (_priceAtInsurance * _tokens * _plan * _timePeriod * conversionRate) / (10 ** (_decimals * 2 + 2));
        // console.log(dollars);
        // console.log(conversionRate);
        // console.log("Price Payable");
        // console.log(pricePayable);

        return pricePayable;
    }

    function getInsurance(uint8 plan, address assetAddress, uint256 timePeriod, address oracleAddress, uint256 decimals)
        public
        payable
    {
        require(customerToContract[msg.sender] == address(0));
        uint256 tokensInsured = getTokenBalance(assetAddress, msg.sender);
        //decimals left
        uint8 _plan = plans[plan];
        require(_plan != 0, "Invalid Plan");
        uint256 priceAtInsurance = getFeedValueOfAsset(oracleAddress);
        uint256 pricePayable = calculateDepositMoney(tokensInsured, _plan, priceAtInsurance, decimals, timePeriod);
        require(msg.value == (pricePayable), "Not send Insurance Amount");
        address insuranceContract = address(
            new AssetWalletInsurance(
                msg.sender,
                assetAddress,
                tokensInsured,
                _plan,
                timePeriod,
                (address(this)),
                oracleAddress,
                priceAtInsurance,
                decimals
            )
        );
        customerToContract[msg.sender] = insuranceContract;
        contractToCustomer[insuranceContract] = msg.sender;
        customers.push(msg.sender);
    }

    function claimInsurance() public payable {
        // Great Way to stop anyone to call this function by using mapping of contract=>customer
        require(contractToCustomer[msg.sender] != address(0));

        AssetWalletInsurance instance = AssetWalletInsurance(payable(msg.sender));
        uint256 _claimAmount = instance.getClaimAmount();
        uint256 _decimals = instance.decimals();
        require(_claimAmount != 0, "Claim Amount Should not be 0");
        uint256 conversionRate = getUsdToWei();
        uint256 amountSent = (conversionRate * _claimAmount) / 10 ** _decimals;
        // console.log(amountSent);
        require(amountSent < address(this).balance, "Not enough Funds in Contract");
        (bool sent,) = msg.sender.call{value: amountSent}("");
        require(sent, "Transaction was not successsful");
    }
}

contract AssetWalletInsurance {
    address public immutable owner;
    address public immutable assetAddress;
    uint256 public immutable tokensInsured;
    uint256 public immutable plan;
    uint256 public immutable timePeriod;
    uint256 public claimAmount;
    address public immutable factoryContract;
    address public immutable oracleAddress;
    uint256 public priceAtInsurance;
    uint256 public decimals;
    bool public claimed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    constructor(
        address _owner,
        address _assetAddress,
        uint256 _tokensInsured,
        uint256 _plan,
        uint256 _timePeriod,
        address _factoryContract,
        address _oracleAddress,
        uint256 _priceAtInsurance,
        uint256 _decimals
    ) {
        owner = _owner;
        assetAddress = _assetAddress;
        tokensInsured = _tokensInsured;
        plan = _plan;
        timePeriod = block.timestamp + _timePeriod * 2629743; //validity in minutes
        factoryContract = _factoryContract;
        oracleAddress = _oracleAddress;
        priceAtInsurance = _priceAtInsurance;
        decimals = _decimals;
    }

    function verifyInsurance() internal onlyOwner {
        require(timePeriod > block.timestamp, "Oops your Insurance Expired");
        require(!claimed);
        uint256 currentPrice = getFeedValueOfAsset(oracleAddress);
        // console.log("Current Price");
        // console.log(currentPrice);
        require(currentPrice < priceAtInsurance, "There is no change in Asset");
        uint256 totalAmount = getInsuranceAmount(currentPrice);
        // console.log(totalAmount);
        require(totalAmount > 0);
        uint256 maximumClaimableAmmount = (totalAmount * plan) / 10;
        if (totalAmount < maximumClaimableAmmount) {
            claimAmount = totalAmount;
        } else {
            claimAmount = maximumClaimableAmmount;
        }
    }

    function getTokenBalance(address tokenAddress, address accountAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(accountAddress);
    }

    function getInsuranceAmount(uint256 _currentPrice) public view returns (uint256) {
        return (((priceAtInsurance - _currentPrice) * tokensInsured) / 10 ** decimals);
    }

    function getFeedValueOfAsset(address _oracleAddress) public view returns (uint256) {
        AggregatorV3Interface priceConsumer = AggregatorV3Interface(_oracleAddress);
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = priceConsumer.latestRoundData();
        return uint256(price);
    }

    function claim() public onlyOwner {
        require(!claimed, "Already Claimed Reward");
        verifyInsurance();
        // console.log("Claim amount is //////////////");
        // console.log(claimAmount);
        claimed = true;
        (bool success,) = factoryContract.call(abi.encodeWithSignature("claimInsurance()"));
        require(success, "Transaction Failed in claim");
    }

    function getClaimAmount() public view returns (uint256) {
        return claimAmount;
    }

    function isClaimed() public view returns (bool) {
        return claimed;
    }

    receive() external payable {}

    function withdrawClaim() public payable onlyOwner {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Failed Transaction");
    }
}
