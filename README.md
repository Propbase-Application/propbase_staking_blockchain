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

Replace Line 128 with the following line

```
const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
```

Run compile

```
aptos move compile  --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c
```

## Test

Add the following line in Move.toml under [addresses]

```
propbase = "0x1"
```

Replace Line 128 with the following line

```
const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
```

Run Test

```
aptos move test  --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c --ignore-compile-warnings
```

## Coverage Summary

Add the following line in Move.toml under [addresses]
propbase = "0x1"

```
aptos move test --coverage --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c --ignore-compile-warnings
```

## Functional Coverage Summary

Add the following line in Move.toml under [addresses]
propbase = "0x1"

```
aptos move coverage summary --summarize-functions --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c
```

## Achieved Coverage

```
Test result: OK. Total tests: 125; passed: 125; failed: 0
+-------------------------+
| Move Coverage Summary   |
+-------------------------+
Module 0000000000000000000000000000000000000000000000000000000000000001::propbase_staking
>>> % Module coverage: 95.00
+-------------------------+
| % Move Coverage: 95.00  |
+-------------------------+
```

## Publish via resource account

Replace it with actual PROPS coin address

```
0xe50684a338db732d8fb8a3ac71c4b8633878bd0193bca5de2ebc852a83b35099::propbase_coin::PROPS
```

```
aptos move create-resource-account-and-publish-package --seed [seed] --address-name propbase --profile default --named-addresses source_addr=[default account's address]
```

## Example Function Invoking commands

```
aptos move create-resource-account-and-publish-package --seed 1452 --address-name propbase --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c

```

Example of created resource account address 1a3fc28a4c5e25d6d2acf434a0ba32291ec61c43021420a9dec6e4611fa2092c

```
aptos move run --function-id 74b4167b6a74da131e2f410d716882c1c22314d9cce2acd9c1dcb1d1dcf7452f::propbase_staking::set_admin --args address:0x477c63b95a81fa8aec975044c13fb63494ca928b58800c668acd7a64fec544ba
```

```
aptos move run --function-id 18327b2f9ea8450beb12074deeb6a723a69dab2fc2b9d39110ad25341fda8468::propbase_staking::set_treasury --args address:0x746f4a1e6501f852bb31039ee1ec8d9e8be58a0193483d7168b4b21ad1ee5897
```

```
aptos move run --function-id 18327b2f9ea8450beb12074deeb6a723a69dab2fc2b9d39110ad25341fda8468::propbase_staking::set_reward_treasurer --args address:0x746f4a1e6501f852bb31039ee1ec8d9e8be58a0193483d7168b4b21ad1ee5897
```
