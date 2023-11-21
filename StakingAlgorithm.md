# $PROPS staking algorithm

simple interest to be calculated based on the time left on the epoch

# Long term staking example

```
Assuming this is a Long term => 40% APY, Jan 01, 2024 to Dec 31, 2024
number of days in epoch = epoch_in_days = 366 days

Assuming the observer is visiting the days at the exact time always.

Pool cap => 20 million , 40% APY,  reward =  capped

Jan 1 - User stake -> 100 PROPS -> Principal (P) = 100
Jan 2 - rewards accumulated = PNR/100
    P = Principal = 100
    N = (current_time in days - last_staked_time in days) / epoch_in_days = 1 / 366
    R = 40
    rewards = P * ((current_time - last_staked_time) / epoch_in_days) * R / 100

    rewards = 100 * (1/366) * 40 / 100 = 0.10928961748633881


Jan 31 - rewards accumulated
    rewards = P * ((current_time - last_staked_time) / epoch_in_days) * R / 100
    rewards = 100 * (30/366) * 40 / 100 = 3.2786885245901636


Feb 01 - rewards accumulated
    rewards = P * ((current_time - last_staked_time) / epoch_in_days) * R / 100
    rewards = 100 * (31/366) * 40 / 100 = 3.387978142076503


Feb 01 - User stake -> another 100 PROPS -> Principal (P) Total = 200
    set rewards_accumulated = rewards = P * ((current_time - last_staked_time) / epoch_in_days) * R / 100
    rewards_accumulated = 100 * (31/366) * 40 / 100
    set rewards_accumulated = 3.387978142076503
    set rewards_accumulation_calculated_time = current_time
    set P = 200

Feb 02 - rewards accumulated =

    Approach :=> rewards so far till last staked + rewards for days since last staked =

    rewards = rewards_accumulated + (P * ((current_time - rewards_accumulation_calculated_time) / 366) * R / 100 )
    rewards = 3.387978142076503 + (200 * (1/366) * 40 / 100)
    rewards = 3.606557377049181


Feb 29 - rewards accumulated
    rewards = rewards_accumulated + (P * ((current_time - rewards_accumulation_calculated_time) / 366) * R / 100 )
    rewards = 3.387978142076503 + (200 * (28 / 366) * 40 / 100)
    rewards = 9.508196721311476

March 1 - user unstake 100
    rewards_accumulated = rewards_accumulated + (P * ((current_time - rewards_accumulation_calculated_time) / 366) * R / 100 )
    rewards_accumulated = 3.387978142076503 + (200 * (29 / 366) * 40 / 100)
    set rewards_accumulated = 9.726775956284154
    set rewards_accumulation_calculated_time = current_time
    set P = 100

    total_returns = P + PNR/100
    total_returns = 200 + 9.726775956284154
    total_returns = 209.726775956284154

    penalty = 5% = 0.05
    total_penalty = withdraw * penalty
    total_pentaly = 100 * 0.05 = 5 $PROPS == ?
    Qn - total_pentaly goes to treasury after period ends - can we hold the penalty in contract till the period end  the treasurer can claim the penalty ?
    Ans -> treasurer - need to transfer rewards at any time when the penalty is deducted
    withdraw = 100

    The UX should show the calculation of penalty as follows:
    entered amount = 100 , penalty = 100 * 0.05 = 5
    actual withdraw amount = 100 - 5 = 95
    user to confirm



    validation to check if user has staked amount >= 100
    actual withdraw amount = 100 - 5 = 95


    total_returns = total_returns - withdraw
    total_returns = 209.726775956284154 - 100
    total_returns = 99.72677595628414


    Rewards - 2 - first
    Capital - 100 - second

after withdraw:
   Capital - 2 - second
    Rewards - 0 - first

    no fee for reward claim

When user unstake, there are 3 options, which is best?
    - should the reward (first) and capital be withdrawn
    - only capital be withdrawn, rewards be claimed as per vesting schedule - no exit strategy
    - separate exit strategy - unstake only, unstake & exit (if total capital is to be withdrawn)


March 2 - rewards accumulated
    rewards_accumulated = rewards_accumulated + (P * ((current_time - rewards_accumulation_calculated_time) / 366) * R / 100 )
    rewards_accumulated = 9.726775956284154 + (100 * (1 / 366) * 40 / 100)
    rewards_accumulated = 9.836065573770492


March 3 - user stakes 150
    rewards_accumulated = rewards_accumulated +  (P * ((current_time - rewards_accumulation_calculated_time) / 366) * R / 100)
    rewards_accumulated = 9.726775956284154 + (100 * (2 / 366) * 40 / 100)
    rewards_accumulated = 9.945355191256832


When user stakes or unstake,
    set rewards_accumulated
    set rewards_accumulation_calculated_time = current_time
    set P =  effective available principal amount


initial value, rewards_accumulated = 0

IF rewards_accumulated
    rewards = rewards_accumulated +  (P * ((current_time - rewards_accumulation_calculated_time) / 366) * R / 100)
ELSE
    rewards = P * ((current_time - last_staked_time) / epoch_in_days) * R / 100

Changes:

- claim rewards any time
- claim reward and capital together at the end of period, without a vesting schedule
- unstake -> only capital, penalty - treasurer
- setting configs to check on the balance of rewards in contract
- all rewards should be placed in contract before setting configs, this way we can restrict to check if the rewards are available in the contract or not.

- no of seconds in year
- min investment amount
- status of the pool in contract


```
