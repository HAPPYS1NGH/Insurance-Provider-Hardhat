// SPDX-License-Identifier: GPL-3.0
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity 0.8.18;

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Sepolia
     * Aggregator: BTC/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    /*
    Mumbai
    USDC / USD
    0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0

    ETH / USD
    0x0715A7794a1dc8e42615F059dD6e406A6594651A
    */
    constructor(address _assetAddress) {
        priceFeed = AggregatorV3Interface(_assetAddress);
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}
