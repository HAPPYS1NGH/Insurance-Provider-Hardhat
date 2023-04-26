# Insurance Project

There are two contracts which are based upon Factory Model.

## ContractInsurance

This contract insures the smart contract against any cause of loss / withdraw of funds.
The user can choose between 3 plans which insure 10, 50 and 100% of loss.
Assumption being all claims are legitimate.

## AssetInsurance

This contract insures the Tokens against any cause of loss in value.
The user can choose between 3 plans which insure 10, 50 and 100% of loss.
Using Oracles to fetch the price Feed Data.
The price feed data is checked using Oracles on Local mainet fork using Foundry
USDC is used as it have fallen in price on 11 March 2023
That repository could be accessed here https://github.com/HAPPYS1NGH/Token-Insurance.
