# propbase staking resources

## Resources

### StakeApp - stored under resource account

```
    app_name: Name of the stake pool.

    signer_cap: Signer capability of the resourse account.

    admin: address of the admin, who controls the major functionalities.

    treasury: address of the treasury who receives the PROPS from the contract.

    reward_treasurer: address of the reward treasury who deposits the PROPS to contract.

    min_stake_amount: minimum PROPS that can be staked.

    max_stake_amount: maximum PROPS that can be staked.

    emergency_locked: flag to track if an emergency is declared.

    excess_reward_calculated: flag to track if the excess reward is calculated by admin/treasury. This is set to true only when the total reward of all users are calculated. When this is true, then treasury can withdraw excess rewards.

    reward: deposited reward from the reward treasury. This is incremented when the reward treasury deposits PROPS to contract. Reward treasury cannot deposit rewards after stake pool has started.

    required_rewards: reward calculated from pool_cap, pool period, pool interest rate. This is the maximum reward that needs to be deposited in the contract by reward_treasurer.

    excess_reward_calculated_addresses: address of the users whose rewards are calculated for the excess reward calculation.

    epoch_emergency_stop_time: timestamp at which emergency was declared.

    emergency_asset_distributed_addressess: address of the user whose assets were distributed in emergency.
```

### StakePool - stored under resource account

```
    pool_cap: maximum limit of the PROPS that can be staked in the pool from all users.

    epoch_start_time: start time of the pool at which users can participate in staking.

    epoch_end_time: end time of the pool at which users cannot participate in staking anymore.

    interest_rate: APY value of the pool at which rewards are calculated.

    penalty_rate: fee applied when a user unstakes.

    seconds_in_year: number of seconds in a year to accommodate the leap year in reward calculation. This can be either 31536000 (SECONDS_IN_NON_LEAP_YEAR) or 31622400 (SECONDS_IN_LEAP_YEAR) based on the year and month of the pool.

    staked_amount: total PROPS staked in the pool by all users.

    total_penalty: total penalty fee in PROPS from all users.

    unclaimed_reward_withdraw_time: time after pool end time, after which the rewards that are unclaimed by the user is withdrawn by treasury. Default is given as 2 year after pool end time. This can be extended by admin at any time.

    unclaimed_reward_withdraw_at: timestamp exactly after which the rewards that are unclaimed by the user is withdrawn by treasury. Deafult is given as pool_end_time + 2 years. This can be extended by admin at any time.

    staked_addressess: wallet addresses of all users that are staked in the pool.
```

### RewardPool - stored under resource account

```
    available_rewards: reward PROPS available in the contract at any given time. This is incremented when reward_treasury deposits the PROPS and decremented when users withdraw the rewards.
```

### ClaimPool - stored under resource account

```
    total_rewards_claimed: total rewards that are claimed by all users.

    total_claimed_principal: total staked amount that are claimed by all users.

    claimed_rewards: contains the address and the rewards claimed by all users.
```

### UserInfo - stored under user account

```
    principal: the amount staked by the user available in the pool at given time.

    withdrawn: the amount unstaked by the user at given time.

    staked_items: the occurences of the staking of the user containing the time and amount of stake.

    unstaked_items: the occurences of the unstaking of the user containing the time and amount of unstake.

    accumulated_rewards: rewards are calculated and summed up whenever user stakes, unstakes and claim rewards.

    rewards_accumulated_at: timestamp at which accumulated_rewards are calculated.

    last_staked_time: Last staked time of the user.

    first_staked_time: First staked time of the user. Used to identify when the first unstake can be done by the user.

    is_total_earnings_withdrawn: Flag to track if the user has claimed all principal and reward after the pool ended.
```
