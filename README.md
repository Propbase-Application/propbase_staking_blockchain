# propbase-stacking

propbase stacking integrations

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
propbase = "0x1"

```
    const PROP_COIN_TEST:vector<u8> = b"0x1::prop_coin::PROP";
```

    replace PROP_COIN code with PROP_COIN_TEST

```
aptos move compile  --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c
```

## Test

Add the following line in Move.toml under [addresses]
propbase = "0x1"

```
aptos move test  --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c --ignore-compile-warnings
```

## Coverage

Add the following line in Move.toml under [addresses]
propbase = "0x1"

```
aptos move test --coverage --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c --ignore-compile-warnings
```

```
+-------------------------+
| Move Coverage Summary   |
+-------------------------+
Module 0000000000000000000000000000000000000000000000000000000000000001::propbase_staking
>>> % Module coverage: 95.00
+-------------------------+
| % Move Coverage: 95.00  |
+-------------------------+
```

## Coverage Summary

Add the following line in Move.toml under [addresses]
propbase = "0x1"

```
aptos move coverage summary --summarize-functions --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c
```

## Publish via resource account

replace it with actual PROP coin address

```
    use propbase::prop_coin::{Self, PROP};
```

```

    "0x1::prop_coin::PROP"
```

```
aptos move create-resource-account-and-publish-package --seed [seed] --address-name propbase --profile default --named-addresses source_addr=[default account's address]
```

## Example Function Invoking commands

```
aptos move create-resource-account-and-publish-package --seed 1404 --address-name propbase --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c

```

Example of created resource account address c70b189ae7a42235d033331f7cda60f6a27e5fa94044cea6fed3ffdb402079be

```
aptos move run --function-id c70b189ae7a42235d033331f7cda60f6a27e5fa94044cea6fed3ffdb402079be::propbase_staking::set_admin --args address:0xafa4e5cb3e5e0c1c025b8ddca850d5544867aa48338c713fea4dc3531e28c0fe
```

0x6f9a565aa86c0c2c0c8b2235f6675e53948a6d97935d0126bdf4867e02024039
0x70b7a62c50e2f8c7c65cff9d204becbda07d08584923c25ead1bc9a6192b8f4b
0xd2260051b51cec586176e544fc28900756e33c4527fcca0b57554d6eb07b0f54
0xafa4e5cb3e5e0c1c025b8ddca850d5544867aa48338c713fea4dc3531e28c0fe

```
aptos move run --function-id 18327b2f9ea8450beb12074deeb6a723a69dab2fc2b9d39110ad25341fda8468::propbase_staking::set_treasury --args address:0x746f4a1e6501f852bb31039ee1ec8d9e8be58a0193483d7168b4b21ad1ee5897
```

```
0x639fe6c230ef151d0bf0da88c85e0332a0ee147e6a87df39b98ccbe228b5c3a9::propbase_coin::PROPS
```

1 aptos = 10^8 octas

1 = 0.000001

1 Propbase= 100000000
