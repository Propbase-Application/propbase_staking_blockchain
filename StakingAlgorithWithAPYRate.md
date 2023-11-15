# $PROPS staking algorithm

simple interest to be calculated based on the time left on the epoch

# Long term staking example

## Simulation

```
Assuming this is a Long term => 40% APY, Jan 01, 2024 to Dec 31, 2024
number of days in epoch = epoch_in_days = 366 days

Assuming the observer is visiting the days at the exact time always.
interval - seconds

Jan 1 - User stake -> 100 PROPS -> Principal (P) = 100
    set stake_1_amount = 100
    set stake_1_time = current_time
    set stake_1_rate = 40

Jan 2 - rewards accumulated = PNR/100
    P = Principal = stake_1_amount = 100
    N = (current_time in days - stake_1_time in days) / epoch_in_days = 1 / 366
    R = stake_1_rate = 40
    rewards = stake_1_amount * ((current_time - stake_1_time) / epoch_in_days) * stake_1_rate / 100

    rewards = 100 * (1/366) * 40 / 100 = 0.10928961748633881


Jan 31 - rewards accumulated
    rewards = stake_1_amount * ((current_time - stake_1_time) / epoch_in_days) * stake_1_rate / 100
    rewards = 100 * (30/366) * 40 / 100 = 3.2786885245901636


Feb 01 - rewards accumulated
    rewards = stake_1_amount * ((current_time - stake_1_time) / epoch_in_days) * stake_1_rate / 100
    rewards = 100 * (31/366) * 40 / 100 = 3.387978142076503


Feb 01 - User stake -> another 100 PROPS -> Principal (P) Total = 200
    set rewards_accumulated = rewards = stake_1_amount * ((current_time - stake_1_time) / epoch_in_days) * stake_1_rate / 100
    rewards_accumulated = 100 * (31/366) * 40 / 100 = 3.387978142076503

    set stake_2_amount = 100

    epoch left = 335 days (366 - 31)
    new rate for new stake = 335 * 40 / 366 = 36.612021857923494 %
    set stake_2_rate = 36.612021857923494

Feb 02 - rewards accumulated =

    rewards =
        (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
        (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 )
    rewards =
        (100 * (32/366) * 40 / 100) +
        (100 * (1/366) * 36.612021857923494 / 100)
    rewards = 3.59730060616919


Feb 29 - rewards accumulated
    rewards =
        (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
        (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 )
    rewards =
        (100 * (60/366) * 40 / 100) +
        (100 * (28/366) * 36.612021857923494 / 100)
    rewards = 9.358296754158081

March 1 - user unstake 100

    rewards =
        (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
        (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 )
    rewards =
        (100 * (61/366) * 40 / 100) +
        (100 * (29/366) * 36.612021857923494 / 100)
    rewards = 9.567619218250767

    set rewards_accumulated = 9.567619218250767

    total_returns = P + PNR/100
                  = stake_1_amount + stake_1_reward + stake_2_amount + stake_2_reward
                  = 100 + (100 * (61/366) * 40 / 100) + 100 + (100 * (29/366) * 36.612021857923494 / 100)
                  = 209.5676192182508


    penalty = 5% = 0.05
    total_penalty = withdraw * penalty
    total_pentaly = 100 * 0.05 = 5 $PROPS == ?
    Qn - total_pentaly goes to treasury after period ends - can we hold the penalty in contract till the period end  the treasurer can claim the penantly ?
    withdraw = 100

    The UX should show the calculation of penalty as follows:
    entered amount = 100 , penalty = 100 * 0.05 = 5
    actual withdraw amount = 100 - 5 = 95
    Qn - Need to verify this

    validation to check if user has staked amount >= 100


    stake_1_time = current_time
    stake_2_time = current_time

    if (withdraw <= stake_2_amount) {
        set stake_2_amount = stake_2_amount - withdraw
        set stake_2_amount = 0
    }



March 2 - rewards accumulated

        rewards =
            (100 * (62/366) * 40 / 100) +
            (100 * (29/366) * 36.612021857923494 / 100)

        rewards = 9.676908835737109 - This is correct one

        if (withdraw <= stake_2_amount) {
            stake_2_amount = stake_2_amount - withdraw
            rewards = rewards_accumulated +
                (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
                (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 )

            rewards = 9.567619218250767 +
                        (100 * (1/366) * 40 / 100 ) +
                        (0 * (1/366) * 36.612021857923494 / 100 )
            rewards = 9.676908835737105

        } elseif (withdraw <= stake_1_amount + stake_2_amount) { // WITHDRAW = 150
            stake_2_amount = 0
            stake_1_amount = withdraw - stake_2_amount = 50
            rewards = rewards_accumulated +
                (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
                (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 )

            rewards = 9.567619218250767 +
                        (50 * (1/366) * 40 / 100 ) +
                        (0 * (1/366) * 36.612021857923494 / 100 )
            rewards = 9.622264026993937

        }


March 3 - user stakes 150
    rewards_accumulated = rewards_accumulated +
        (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
        (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 )
    rewards_accumulated = 9.567619218250767 +
        (100 * (2 / 366) * 40 / 100) +
        (0 * (2 / 366) * 36.612021857923494 / 100)
    rewards_accumulated = 9.786198453223445

    set stake_1_amount = 150
    epoch left = 304 days (366 - 62)
    new rate for new stake = 304 * 40 / 366 = 33.224043715846996 %
    set stake_3_rate = 33.224043715846996
    set stake_2_time = current_time

March 4 - rewards accumulated
    rewards = rewards_accumulated +
        (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
        (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 ) +
        (stake_3_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 )


    rewards = 9.567619218250767 +
        (100 * (3 / 366) * 40 / 100 ) +
        (0 * (3 / 366) * 36.612021857923494 / 100 ) +
        (150 * (1 / 366) * 33.224043715846996 / 100 )
    rewards = 10.03165218429932


```

## Algorithm non optimised

```
When user  unstake,
    set rewards_accumulated
    reset all stake time to be current time
    set stake amount as follows:

    if (withdraw <= stake_2_amount) {
        stake_2_amount = stake_2_amount - withdraw
    } elseif (withdraw <= stake_1_amount + stake_2_amount) {
        stake_2_amount = 0
        stake_1_amount = withdraw - stake_2_amount
    } .... n series


    if(rewards_accumulated) {
         rewards = rewards_accumulated +
            (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
            (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 ) + .... (Sum of n series)
    } else {
        rewards = (stake_1_amount * ((current_time - stake_1_time) / 366) * stake_1_rate / 100 ) +
            (stake_2_amount * ((current_time - stake_2_time) / 366) * stake_2_rate / 100 ) + .... (Sum of n series)
    }



stake_amount = [100, 100]
stake_time = [Jan1, Mar1]
stake_rate = [40, 36.612021857923494]

expected reward:

i = 0
reward = 0
while(i < stake_amount.length) {
    reward = reward + (stake_amount[i] * ((epoch_end_time - stake_time[i]) / 366) * stake_rate[i] / 100 )
}

exact reward so far:

i = 0
reward = 0
while(i < stake_amount.length) {
    reward = reward + (stake_amount[i] * ((current_time - stake_time[i]) / 366) * stake_rate[i] / 100 )
    i ++
}


<!-- Unstake and set rate and amount

if (withdraw <= stake_amount[i]) {
        stake_2_amount = stake_2_amount - withdraw
        return
    }

add_upto_withdraw = 0
i = stake_amount.length - 1
reward = 0
while(i >= 0) {
     if (withdraw <= add_upto_withdraw) {
        stake_2_amount = add_upto_withdraw - withdraw
        return
    } else {
        add_upto_withdraw = add_upto_withdraw + stake_2_amount
    }

}

    elseif (withdraw <= stake_1_amount + stake_2_amount) {
        stake_2_amount = 0
        stake_1_amount = withdraw - stake_2_amount
    }
} -->





```
