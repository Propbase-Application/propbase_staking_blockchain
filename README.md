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
aptos move compile  --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c
```

## Test

Add the following line in Move.toml under [addresses]
propbase = "0x1"

```
aptos move test  --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c --ignore-compile-warnings
```

## Publish via resource account

```
aptos move create-resource-account-and-publish-package --seed [seed] --address-name propbase --profile default --named-addresses source_addr=[default account's address]
```

## Example Function Invoking commands

```
aptos move create-resource-account-and-publish-package --seed 1388 --address-name propbase --named-addresses source_addr=87ab7d47a9b0ac84b856168b68fff06408cc5f1c691a6c5366c3ab116d76d93c

```

Example of created resource account address 18327b2f9ea8450beb12074deeb6a723a69dab2fc2b9d39110ad25341fda8468

```
aptos move run --function-id 18327b2f9ea8450beb12074deeb6a723a69dab2fc2b9d39110ad25341fda8468::propbase_staking::set_admin --args new_admin_address:0x6f9a565aa86c0c2c0c8b2235f6675e53948a6d97935d0126bdf4867e02024039
```

0x6f9a565aa86c0c2c0c8b2235f6675e53948a6d97935d0126bdf4867e02024039
0x70b7a62c50e2f8c7c65cff9d204becbda07d08584923c25ead1bc9a6192b8f4b
0xd2260051b51cec586176e544fc28900756e33c4527fcca0b57554d6eb07b0f54

```
aptos move run --function-id 18327b2f9ea8450beb12074deeb6a723a69dab2fc2b9d39110ad25341fda8468::propbase_staking::set_treasury --args new_treasury_address:0x746f4a1e6501f852bb31039ee1ec8d9e8be58a0193483d7168b4b21ad1ee5897
```

1 aptos = 10^8 octas

1 = 0.000001

1 Propbase= 100000000
