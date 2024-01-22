# propbase-staking

propbase staking integrations

## Initializing commands:

Initialize package with folder structure - To be done only else if the folder structure is not in place.

```
aptos move init --name propbase

```

Initialize admin address

```
aptos init --profile default
```

Initialize admin address and add the admin address in Move.toml under addresses

```
aptos init --profile admin
```

## Compile

Add the following line in Move.toml under [addresses]

```
propbase = "0x1"
```

Replace Line 158 with the following line

```
const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
```

Run compile

```
aptos move compile  --named-addresses source_addr=12347d47a9b0ac564856168b68fff06408cc5f1c691yur5366c3ab116d76rsdf --save-metadata
```

## Test

Add the following line in Move.toml under [addresses]

```
propbase = "0x1"
```

Replace Line 158 with the following line

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

Replace Line 158 with the following line

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

Replace Line 158 with the following line

```
const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
```

Run Function-wise Test Coverage

```
aptos move coverage summary --summarize-functions --named-addresses source_addr=12347d47a9b0ac564856168b68fff06408cc5f1c691yur5366c3ab116d76rsdf
```

## Achieved Test Coverage

```
Test result: OK. Total tests: 180; passed: 180; failed: 0
+-------------------------+
| Move Coverage Summary |
+-------------------------+
Module 0000000000000000000000000000000000000000000000000000000000000001::propbase_staking
>>> % Module coverage: 95.42
+-------------------------+
| % Move Coverage: 95.42  |
```

## Publish via resource account in Testnet/Devnet

Make sure all local changes are reverted and publish contract by the command as follows

```
aptos move create-resource-account-and-publish-package --seed [seed] --address-name propbase --profile default --named-addresses source_addr=[default account's address]
```

## Publish via resource account in Mainnet

Make sure all local changes are reverted.
Replace line 158 with actual PROPS coin address

```
0xe50684a338db732d8fb8a3ac71c4b8633878bd0193bca5de2ebc852a83b35099::propbase_coin::PROPS
```

```
aptos move create-resource-account-and-publish-package --seed [seed] --address-name propbase --profile default --named-addresses source_addr=[default account's address]
```

## Example Function Invoking commands

```
aptos move create-resource-account-and-publish-package --seed 1 --address-name propbase --named-addresses source_addr=12347d47a9b0ac564856168b68fff06408cc5f1c691yur5366c3ab116d76rsdf --included-artifacts none

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
