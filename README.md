# propbase-staking

PROPS Staking App is where one can stake $PROPS and gain $PROPS as rewards.
The project is developed using the Move language, Aptos standard libraries, and runs on top of the Aptos blockchain.

## App Highlights:

Effortless Staking: Stake PROPS seamlessly for hassle-free earning and engagement.

Daily Rewards: Claim your gains daily, injecting dynamism into your staking journey.

Transparent Fees: Enjoy clear fee structures, ensuring you stay in control of your rewards.

Flexible Unstaking: Unstake your assets at any time, offering unparalleled flexibility.

Fixed APY: Experience stability with a fixed Annual Percentage Yield (APY).

Capped Pools: Balanced and sustainable staking environments with capped pool limits.

First-Come, First-Served: Secure your spot in the rewarding journey with this simple participation approach.

## Contract Technical Features:

The project is developed using the Move language, Aptos standard libraries, and runs on top of the Aptos blockchain.

The contract is designed to be deployed under a resource account. The contract lives under the resource address, making the contract cannot be controlled by any private key. Read more about resource account [here](https://aptos.dev/move/move-on-aptos/resource-accounts).

The contract package is an immutable one, hence no one can update it.

Commands to install aptos CLI and initializing commands are given below.

The folder structure is explained in [project_folder_structure.png](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/docs/project_folder_structure.png).

The package meta info and dependent aptos librabries are mentioned in [Move.toml](https://github.com/Propbase-Application/propbase_staking_blockchain/blob/main/Move.toml).

Contract highlights and the roles in the contract are mentioned at [staking_highlights.png](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/docs/staking_highlights.png).

Functional use cases, flow chart diagram, contract time line diagrams are mentioned at [staking_functional_diagram.png](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/docs/staking_functional_diagram.png).

The contract architecture diagram is given at [Propbase_contract_architecture_diagram.png](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/docs/Propbase_contract_architecture_diagram.png).

Contract source files are at [propbase_staking.move](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/sources/propbase_staking.move).

Test files are here at [propbase_staking_tests.move](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/tests/propbase_staking_tests.move). Commands for testing are mentioned down below.

Deployment commands are given down below.

All the docs are available at [docs](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/docs)

## Install Aptos CLI

```
https://aptos.dev/tools/aptos-cli/install-cli/
```

## Initializing commands:

Initialize package with folder structure - To be done only else if the folder structure is not in place.

```
aptos move init --name propbase

```

Initialize admin address

```
aptos init --profile default
```

Initialize any wallet profile as follows

```
aptos init --profile admin
```

## Compile

Add the following line in Move.toml under [addresses]

```
propbase = "0x1"
```

Replace Line 164 with the following line

```
const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
```

Run compile

```
aptos move compile --named-addresses source_addr=[default or any account's address]
```

```
aptos move compile  --named-addresses source_addr=12347d47a9b0ac564856168b68fff06408cc5f1c691yur5366c3ab116d76rsdf --save-metadata
```

## Test

Test files are here at [propbase_staking_tests.move](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/tests/propbase_staking_tests.move). Commands for testing are mentioned down below.

There is a [PROP.move](https://github.com/Propbase-Application/propbase_staking_blockchain/tree/main/sources/test/PROP.move) file with address 0x1 to mimick the $PROPS coin in test cases. Hence this 0x1 address needs to be hard coded in the contract and in Move.html for running tests.

Since the contract uses resource account, for testing the contract, we need to create a different resource address. This creates a situation where the signer capability are different for test mode and non-test mode. Hence some functions where signer capability are directly required as in init_module are not directly testable in test mode. Here we wont be able to achieve the test coverage.

Commands to run tests are as follows:

Add the following line in Move.toml under [addresses]

```
propbase = "0x1"
```

Replace Line 164 with the following line

```
const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
```

Run Test

```
aptos move test --named-addresses source_addr=12347d47a9b0ac564856168b68fff06408cc5f1c691yur5366c3ab116d76rsdf --ignore-compile-warnings
```

## Test Coverage Summary

Add the following line in Move.toml under [addresses]

```
propbase = "0x1"
```

Replace Line 164 with the following line

```
const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
```

Run Test Coverage

```
aptos move test --coverage --named-addresses source_addr=12347d47a9b0ac564856168b68fff06408cc5f1c691yur5366c3ab116d76rsdf --ignore-compile-warnings
```

## Function-wise Test Coverage Summary

Add the following line in Move.toml under [addresses]

```
propbase = "0x1"
```

Replace Line 164 with the following line

```
const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
```

Run Function-wise Test Coverage

```
aptos move coverage summary --summarize-functions --named-addresses source_addr=12347d47a9b0ac564856168b68fff06408cc5f1c691yur5366c3ab116d76rsdf
```

## Achieved Test Coverage

```
Test result: OK. Total tests: 214; passed: 214; failed: 0
+-------------------------+
| Move Coverage Summary   |
+-------------------------+
Module 0000000000000000000000000000000000000000000000000000000000000001::propbase_staking
>>> % Module coverage: 95.08
+-------------------------+
| % Move Coverage: 95.08  |
+-------------------------+
```

## Publish via resource account in Testnet/Devnet

Make sure all local changes are reverted.
Replace line 164 with actual PROPS coin address

```
0xd8221ad202d71302027adab3706f9e8731b76b870bc1a163b0922ac5d91a905f::propbase_coin::TEST_PROPS
```

```
aptos move create-resource-account-and-publish-package --seed [seed] --address-name propbase --profile default --named-addresses source_addr=[default account's address]
```

## Publish via resource account in Mainnet

Make sure all local changes are reverted.
Replace line 164 with actual PROPS coin address

```
0xe50684a338db732d8fb8a3ac71c4b8633878bd0193bca5de2ebc852a83b35099::propbase_coin::PROPS
```

```
aptos move create-resource-account-and-publish-package --seed [seed] --address-name propbase --profile default --named-addresses source_addr=[default account's address] --included-artifacts none
```

## Example Function Invoking commands

```
aptos move create-resource-account-and-publish-package --seed 1 --address-name propbase --named-addresses source_addr=12347d47a9b0ac564856168b68fff06408cc5f1c691yur5366c3ab116d76rsdf --included-artifacts none --profile admin

```

Example of created resource account address

```
7g9aa29b11420032ar7ua577e6a33552060a887a21e4228b1cb687eb9cd22b34
```

```
aptos move run --function-id 7g9aa29b11420032ar7ua577e6a33552060a887a21e4228b1cb687eb9cd22b34::propbase_staking::set_admin --args address:0x477c63b95a81fa8aec975044c13fb63494ca928b58800c668acd7a64fec544ba
```

```
aptos move run --function-id 7g9aa29b11420032ar7ua577e6a33552060a887a21e4228b1cb687eb9cd22b34::propbase_staking::set_treasury --args address:0x746f4a1e6501f852bb31039ee1ec8d9e8be58a0193483d7168b4b21ad1ee5897
```

```
aptos move run --function-id 7g9aa29b11420032ar7ua577e6a33552060a887a21e4228b1cb687eb9cd22b34::propbase_staking::set_reward_treasurer --args address:0x746f4a1e6501f852bb31039ee1ec8d9e8be58a0193483d7168b4b21ad1ee5897
```
