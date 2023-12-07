module propbase::propbase_staking {

    #[test_only]
    friend propbase::propbase_staking_tests;

    use std::string::{ Self, String };
    use std::signer;
    use std::vector;
    use std::error;
    use aptos_std::table_with_length::{ Self as Table, TableWithLength };
    use aptos_std::type_info;
    use aptos_framework::event::{ Self, EventHandle };
    use aptos_framework::coin::{ Self, Coin };
    use aptos_framework::aptos_account;
    use aptos_framework::account::{ Self, SignerCapability };
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;
    
    struct StakeApp has key {
        app_name: String,
        signer_cap: account::SignerCapability,
        admin: address,
        treasury: address,
        reward_treasurers: TableWithLength<address, bool>,
        min_stake_amount: u64,
        set_admin_events: EventHandle<SetAdminEvent>,
        set_treasury_events: EventHandle<SetTreasuryEvent>,
        set_reward_treasurers_events: EventHandle<vector<address>>,
        unset_reward_treasurers_events: EventHandle<vector<address>>,
    }

    struct StakePool has key {
        pool_cap: u64,
        epoch_start_time: u64,
        epoch_end_time: u64,
        interest_rate: u64,
        penalty_rate: u64,
        seconds_in_year: u64,
        staked_amount: u64,
        total_penalty: u64,
        unclaimed_coin_withdraw_at: u64,
        set_pool_config_events: EventHandle<SetStakePoolEvent>,
    }

    struct RewardPool has key {
        available_rewards: u64,
        updated_rewards_events: EventHandle<UpdateRewardsEvent>,
    }

    struct ClaimPool has key {
        total_claimed: u64,
        claimed_rewards: TableWithLength<address, u64>,
        update_total_claimed_events: EventHandle<ClaimRewardEvent>,
    }

    struct UserInfo has key {
        principal: u64,
        withdrawn: u64,
        staked_items: vector<Stake>,
        unstaked_items: vector<Stake>,
        accumulated_rewards: u64,
        rewards_accumulated_at: u64,
        last_staked_time: u64,
        first_staked_time: u64,
        is_total_earnings_withdrawn: bool,
        stake_events: EventHandle<StakeEvent>,
        unstake_events: EventHandle<UnStakeEvent>,
    }

    struct StakeEvent has drop, store{
        principal: u64,
        amount: u64,
        accumulated_rewards: u64,
        staked_time: u64,
    }

    struct UnStakeEvent has drop, store{
        withdrawn: u64,
        amount: u64,
        penalty: u64,
        accumulated_rewards: u64,
        unstaked_time: u64,
    }

    struct Stake has drop, store {
        timestamp:u64,
        amount: u64,
    }

    struct ClaimRewardEvent has drop, store{
        timestamp:u64,
        claimed_amount: u64,
    }

    struct SetAdminEvent has drop, store {
        old_admin: address,
        new_admin: address,
    }

    struct SetTreasuryEvent has drop, store {
        old_treasury: address,
        new_treasury: address,
    }

    struct UpdateRewardsEvent has drop, store {
        old_rewards: u64,
        new_rewards: u64,
    }

    struct SetStakePoolEvent has drop, store {
        pool_name: String,
        pool_cap: u64,
        epoch_start_time: u64,
        epoch_end_time: u64,
        interest_rate: u64,
        penalty_rate: u64,
        seconds_in_year: u64
    }

    const PROPS_COIN:vector<u8> = b"0x639fe6c230ef151d0bf0da88c85e0332a0ee147e6a87df39b98ccbe228b5c3a9::propbase_coin::PROPS";
    // const SECONDS_IN_DAY: u64 = 86400;
    // const UNCLAIMED_COIN_WITHDRAW_PERIOD: u64 = 15780000;
    // const PROPS_COIN:vector<u8> = b"0x1::propbase_coin::PROPS";
    const SECONDS_IN_DAY: u64 = 1;
    const UNCLAIMED_COIN_WITHDRAW_PERIOD: u64 = 2;
    const SECONDS_IN_NON_LEAP_YEAR: u64 = 31536000;
    const SECONDS_IN_LEAP_YEAR: u64 = 31622400;

    const E_NOT_AUTHORIZED: u64 = 1;
    const E_NOT_NOT_A_TREASURER: u64 = 2;
    const E_STAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME: u64 = 4;
    const E_STAKE_POOL_EXHAUSTED : u64 = 5;
    const E_STAKE_ALREADY_STARTED: u64 = 6;
    const E_NOT_PROPS: u64 = 7;
    const E_INVALID_AMOUNT: u64 = 8;
    const E_NOT_IN_STAKING_RANGE: u64 = 9;
    const E_NOT_STAKED_USER: u64 = 10;
    const E_ACCOUNT_DOES_NOT_EXIST: u64 = 11;
    const E_STAKE_POOL_INTEREST_OUT_OF_RANGE: u64 = 12;
    const E_STAKE_POOL_PENALTY_OUT_OF_RANGE: u64 = 13;
    const E_STAKE_POOL_CAP_OUT_OF_RANGE : u64 = 14;        
    const E_STAKE_START_TIME_OUT_OF_RANGE : u64 = 15;
    const E_STAKE_END_TIME_OUT_OF_RANGE : u64 = 16;
    const E_STAKE_POOL_NAME_CANT_BE_EMPTY : u64 = 17;
    const E_AMOUNT_MUST_BE_GREATER_THAN_ZERO : u64 = 18;
    const E_REWARD_NOT_ENOUGH : u64 = 19;
    const E_STAKE_MIN_STAKE_MUST_BE_GREATER_THAN_ZERO : u64 = 20;
    const E_STAKE_NOT_ENOUGH : u64 = 21;
    const E_SECONDS_IN_YEAR_INVALID: u64 = 22;
    const E_NOT_ENOUGH_REWARDS_TRY_AGAIN_LATER: u64 = 23;
    const E_STAKE_IN_PROGRESS : u64 = 24;
    const E_NOT_IN_CLAIMING_RANGE : u64 = 25;
    const E_WITHDRAW_UNCLAIMED_NOT_AVAILABLE: u64 = 26;
    const E_EARNINGS_ALREADY_WITHDRAWN: u64 = 27;

    fun init_module(resource_account: &signer) {
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_account, @source_addr);
        init_config(resource_account, resource_signer_cap);
    }

    #[test_only]
    public(friend) fun init_test(resource_account: &signer, resource_signer_cap: SignerCapability) {
        init_config(resource_account, resource_signer_cap);
    }

    fun init_config(resource_account: &signer, resource_signer_cap: SignerCapability) {
        move_to(resource_account, StakeApp {
            app_name: string::utf8(b""),
            signer_cap: resource_signer_cap,
            admin: @source_addr,
            treasury: @source_addr,
            reward_treasurers: Table::new(),
            min_stake_amount: 0,
            set_admin_events: account::new_event_handle<SetAdminEvent>(resource_account),
            set_treasury_events: account::new_event_handle<SetTreasuryEvent>(resource_account),
            set_reward_treasurers_events: account::new_event_handle<vector<address>>(resource_account),
            unset_reward_treasurers_events: account::new_event_handle<vector<address>>(resource_account)
        });
        move_to(resource_account, StakePool {
            pool_cap: 0,
            epoch_start_time: 0,
            epoch_end_time: 0,
            interest_rate: 0,
            penalty_rate: 0,
            seconds_in_year: 0,
            staked_amount: 0,
            total_penalty: 0,
            unclaimed_coin_withdraw_at: 0,
            set_pool_config_events: account::new_event_handle<SetStakePoolEvent>(resource_account),
        });
        move_to(resource_account, RewardPool {
            available_rewards: 0,
            updated_rewards_events: account::new_event_handle<UpdateRewardsEvent>(resource_account),
        });
        move_to(resource_account, ClaimPool {
            total_claimed: 0,
            claimed_rewards: Table::new(),
            update_total_claimed_events: account::new_event_handle<ClaimRewardEvent>(resource_account), 
        });
    }

    public entry fun set_admin(
        admin: &signer,
        new_admin_address: address,
    ) acquires StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let old_admin = contract_config.admin;

        assert!(account::exists_at(new_admin_address), error::invalid_argument(E_ACCOUNT_DOES_NOT_EXIST));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        contract_config.admin = new_admin_address;

        event::emit_event<SetAdminEvent>(
            &mut contract_config.set_admin_events,
            SetAdminEvent {
                old_admin: old_admin,
                new_admin: new_admin_address
            }
        );
    }

    public entry fun set_treasury(
        admin: &signer,
        new_treasury_address: address,
    ) acquires StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let old_treasury = contract_config.treasury;

        assert!(account::exists_at(new_treasury_address), error::invalid_argument(E_ACCOUNT_DOES_NOT_EXIST));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        
        contract_config.treasury = new_treasury_address;

        event::emit_event<SetTreasuryEvent>(
            &mut contract_config.set_treasury_events,
            SetTreasuryEvent {
                old_treasury: old_treasury,
                new_treasury: new_treasury_address
            }
        );
    }

    public entry fun add_reward_treasurers(
        admin: &signer,
        new_treasurers: vector<address>,
    ) acquires StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let index = 0;
        let length = vector::length(&new_treasurers);

        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        
        while (index < length) {
            let element = *vector::borrow(&new_treasurers, index);
            assert!(account::exists_at(element), error::invalid_argument(E_ACCOUNT_DOES_NOT_EXIST));
            Table::upsert<address, bool>(&mut contract_config.reward_treasurers, element, true);
            index = index + 1;
        };

        event::emit_event<vector<address>>(
            &mut contract_config.set_reward_treasurers_events,
            new_treasurers
        );
    }

    public entry fun remove_reward_treasurers(
        admin: &signer,
        new_treasurers: vector<address>,
    ) acquires StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let index = 0;
        let length = vector::length(&new_treasurers);
        
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
       
        while (index < length){
            let element = *vector::borrow(&new_treasurers, index);
            Table::remove<address, bool>(&mut contract_config.reward_treasurers, element);
            index = index + 1;
        };

        event::emit_event<vector<address>>(
            &mut contract_config.unset_reward_treasurers_events,
            new_treasurers
        );
    }

    public entry fun create_or_update_stake_pool(
        admin: &signer,
        pool_name: String,
        pool_cap: u64,
        epoch_start_time: u64,
        epoch_end_time: u64,
        interest_rate: u64,
        penalty_rate: u64,
        min_stake_amount: u64,
        seconds_in_year: u64,
        value_config: vector<bool>
    ) acquires StakePool, StakeApp, RewardPool {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);

        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        assert!((timestamp::now_seconds() < stake_pool_config.epoch_start_time) || stake_pool_config.epoch_start_time == 0, error::permission_denied(E_STAKE_ALREADY_STARTED));

        let set_pool_name = *vector::borrow(&value_config, 0);
        let set_pool_cap = *vector::borrow(&value_config, 1);
        let set_epoch_start_time = *vector::borrow(&value_config, 2);
        let set_epoch_end_time = *vector::borrow(&value_config, 3);
        let set_interest_rate = *vector::borrow(&value_config, 4);
        let set_penalty_rate = *vector::borrow(&value_config, 5);
        let set_min_stake_amount = *vector::borrow(&value_config, 6);
        let set_seconds_in_year = *vector::borrow(&value_config, 7);

        if(set_epoch_start_time && set_epoch_end_time) {
            assert!(epoch_start_time < epoch_end_time, error::invalid_argument(E_STAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME))
        };
        if(set_pool_cap) {
            assert!(pool_cap >= 20000000000, error::invalid_argument(E_STAKE_POOL_CAP_OUT_OF_RANGE));
            stake_pool_config.pool_cap = pool_cap;          
        };
        if(set_epoch_start_time) {
            assert!(epoch_start_time > 0, error::invalid_argument(E_STAKE_START_TIME_OUT_OF_RANGE));
            assert!(epoch_start_time < stake_pool_config.epoch_end_time || stake_pool_config.epoch_end_time == 0, error::invalid_argument(E_STAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
            stake_pool_config.epoch_start_time = epoch_start_time; 
        };
        if(set_epoch_end_time) {
            assert!(epoch_end_time > 0, error::invalid_argument(E_STAKE_END_TIME_OUT_OF_RANGE));
            assert!(epoch_end_time > stake_pool_config.epoch_start_time, error::invalid_argument(E_STAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
            stake_pool_config.epoch_end_time = epoch_end_time;
            stake_pool_config.unclaimed_coin_withdraw_at = epoch_end_time + UNCLAIMED_COIN_WITHDRAW_PERIOD;
        };
        if(set_penalty_rate) {
            assert!(penalty_rate <= 50 && penalty_rate > 0, error::invalid_argument(E_STAKE_POOL_PENALTY_OUT_OF_RANGE));
            stake_pool_config.penalty_rate = penalty_rate;
        };
        if(set_interest_rate) {
            assert!(interest_rate > 0 && interest_rate <= 100, error::invalid_argument(E_STAKE_POOL_INTEREST_OUT_OF_RANGE));
            stake_pool_config.interest_rate = interest_rate;
        };
        if (set_pool_name) {
            assert!(pool_name != string::utf8(b""), error::invalid_argument(E_STAKE_POOL_NAME_CANT_BE_EMPTY));
            contract_config.app_name = pool_name;
        };
        if(set_min_stake_amount) {
            assert!(min_stake_amount > 0, error::invalid_argument(E_STAKE_MIN_STAKE_MUST_BE_GREATER_THAN_ZERO));
            contract_config.min_stake_amount = min_stake_amount;
        };
        if(set_seconds_in_year) {
            assert!(seconds_in_year == SECONDS_IN_NON_LEAP_YEAR || seconds_in_year == SECONDS_IN_LEAP_YEAR, error::invalid_argument(E_SECONDS_IN_YEAR_INVALID));
            stake_pool_config.seconds_in_year = seconds_in_year;
        };

        let period = stake_pool_config.epoch_end_time - stake_pool_config.epoch_start_time ;
        let required_rewards = apply_reward_formula(stake_pool_config.pool_cap,  period, stake_pool_config.interest_rate, stake_pool_config.seconds_in_year);

        assert!(reward_state.available_rewards >= (required_rewards as u64), error::resource_exhausted(E_REWARD_NOT_ENOUGH));

        event::emit_event<SetStakePoolEvent>(
            &mut stake_pool_config.set_pool_config_events,
            SetStakePoolEvent {
                pool_name : contract_config.app_name,
                pool_cap: stake_pool_config.pool_cap,
                epoch_start_time: stake_pool_config.epoch_start_time,
                epoch_end_time: stake_pool_config.epoch_end_time,
                interest_rate: stake_pool_config.interest_rate,
                penalty_rate: stake_pool_config.penalty_rate,
                seconds_in_year: stake_pool_config.seconds_in_year
            }
        );
    }

    public entry fun add_stake<CoinType> (
        user: &signer,
        amount: u64
    ) acquires  UserInfo, StakePool, StakeApp {
        let now = timestamp::now_seconds();
        let user_address = signer::address_of(user);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let contract_config = borrow_global_mut<StakeApp>(@propbase);

        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        assert!(amount >= contract_config.min_stake_amount, error::invalid_argument(E_INVALID_AMOUNT));
        assert!(now >= stake_pool_config.epoch_start_time && now < stake_pool_config.epoch_end_time, error::out_of_range(E_NOT_IN_STAKING_RANGE));
        assert!(now < stake_pool_config.epoch_end_time - SECONDS_IN_DAY, error::out_of_range(E_NOT_IN_STAKING_RANGE));
        assert!(stake_pool_config.staked_amount + amount <= stake_pool_config.pool_cap , error::resource_exhausted(E_STAKE_POOL_EXHAUSTED));
        
        stake_pool_config.staked_amount = stake_pool_config.staked_amount + amount;
        aptos_account::transfer_coins<CoinType>(user, @propbase, amount);

        if(!exists<UserInfo>(user_address)) {
            let stake_buffer = vector::empty<Stake>();
            let unstake_buffer = vector::empty<Stake>();
            vector::push_back(&mut stake_buffer, Stake { timestamp: now, amount });
            move_to(user, UserInfo {
                principal: amount,
                withdrawn: 0,
                staked_items: stake_buffer,
                unstaked_items: unstake_buffer,
                accumulated_rewards: 0,
                rewards_accumulated_at: 0,
                last_staked_time: now,
                first_staked_time: now,
                is_total_earnings_withdrawn: false,
                stake_events: account::new_event_handle<StakeEvent>(user),
                unstake_events: account::new_event_handle<UnStakeEvent>(user),
            });

            let user_state = borrow_global_mut<UserInfo>(user_address);
            event::emit_event<StakeEvent>(
                &mut user_state.stake_events,
                StakeEvent {
                    principal: amount,
                    amount: amount,
                    accumulated_rewards: 0,
                    staked_time: now,
                }
            );
        } else {
            let user_state = borrow_global_mut<UserInfo>(user_address);
            let accumulated_rewards = get_total_rewards_so_far(
                user_state.principal,
                user_state.accumulated_rewards,
                user_state.rewards_accumulated_at,
                user_state.last_staked_time,
                stake_pool_config.interest_rate,
                stake_pool_config.seconds_in_year,
                stake_pool_config.epoch_end_time,
            );

            user_state.accumulated_rewards = (accumulated_rewards as u64);
            user_state.principal = user_state.principal + amount;
            user_state.last_staked_time = now;
            user_state.rewards_accumulated_at = now;
            vector::push_back(&mut user_state.staked_items, Stake { timestamp: now, amount });

            event::emit_event<StakeEvent>(
                &mut user_state.stake_events,
                StakeEvent {
                    principal: user_state.principal,
                    amount: amount,
                    accumulated_rewards: user_state.accumulated_rewards,
                    staked_time: now,
                }
            );
        }
    }

    public entry fun withdraw_stake<CoinType> (
        user: &signer,
        amount: u64
    ) acquires UserInfo, StakeApp, StakePool {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
        implement_unstake<CoinType>(user, &resource_signer, amount);
    }

    #[test_only]
    public entry fun test_withdraw_stake<CoinType>(user:&signer, resource_signer: &signer, amount:u64) acquires StakePool, UserInfo, StakeApp {
        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        implement_unstake<CoinType>(user, resource_signer, amount);
    }

    inline fun implement_unstake<CoinType>(
        user: &signer,
        resource_signer: &signer,
        amount: u64,
    ) acquires UserInfo, StakePool, StakeApp {
        let user_address = signer::address_of(user);
        assert!(exists<UserInfo>(user_address), error::permission_denied(E_NOT_STAKED_USER));
        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));

        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let now = timestamp::now_seconds();
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let user_state = borrow_global_mut<UserInfo>(user_address);

        assert!(now <= stake_pool_config.epoch_end_time, error::out_of_range(0));
        assert!(amount > 0, error::invalid_argument(E_AMOUNT_MUST_BE_GREATER_THAN_ZERO));
        assert!(now >= user_state.first_staked_time + SECONDS_IN_DAY, error::out_of_range(0));
        assert!(user_state.principal >= amount, error::resource_exhausted(E_STAKE_NOT_ENOUGH));

        let accumulated_rewards = get_total_rewards_so_far(
            user_state.principal,
            user_state.accumulated_rewards,
            user_state.rewards_accumulated_at,
            user_state.last_staked_time,
            stake_pool_config.interest_rate,
            stake_pool_config.seconds_in_year,
            stake_pool_config.epoch_end_time,
        );
     
        stake_pool_config.staked_amount = stake_pool_config.staked_amount - amount;
        user_state.accumulated_rewards = (accumulated_rewards as u64);
        user_state.rewards_accumulated_at = now;
        user_state.principal = user_state.principal - amount;
        user_state.withdrawn = user_state.withdrawn + amount;

        vector::push_back(&mut user_state.unstaked_items, Stake { timestamp: now, amount });
        let penalty = amount / 100 * stake_pool_config.penalty_rate ;
        let bal_after_penalty = amount - penalty;
        stake_pool_config.total_penalty = stake_pool_config.total_penalty + penalty;

        aptos_account::transfer_coins<CoinType>(resource_signer, contract_config.treasury, penalty);
        aptos_account::transfer_coins<CoinType>(resource_signer, user_address, bal_after_penalty);

        event::emit_event<UnStakeEvent>(
            &mut user_state.unstake_events,
            UnStakeEvent {
                withdrawn: user_state.withdrawn,
                amount: amount,
                penalty: penalty,
                accumulated_rewards: user_state.accumulated_rewards,
                unstaked_time: now,
            }
        );
    }

    public entry fun add_reward_funds<CoinType>(
        treasurer: &signer,
        amount: u64,
    ) acquires StakeApp, RewardPool {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        assert!(amount > 0, error::invalid_argument(E_AMOUNT_MUST_BE_GREATER_THAN_ZERO));
        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        assert!(Table::contains(&contract_config.reward_treasurers, signer::address_of(treasurer)), error::permission_denied(E_NOT_NOT_A_TREASURER));

        let prev_reward = reward_state.available_rewards;
        let updated_reward = prev_reward + amount;
        reward_state.available_rewards = updated_reward;
        aptos_account::transfer_coins<CoinType>(treasurer, @propbase, amount);

        event::emit_event<UpdateRewardsEvent>(
            &mut reward_state.updated_rewards_events,
            UpdateRewardsEvent {
                old_rewards: prev_reward,
                new_rewards: updated_reward
            }
        );
    }

    inline fun apply_reward_formula(
        principal: u64,
        period: u64,
        interest_rate: u64,
        seconds_in_year: u64
    ): u128 acquires StakePool {
        let interest = ((principal as u128) * (interest_rate as u128));
        let interest_per_sec = interest / (seconds_in_year as u128);
        let remainder = interest % (seconds_in_year as u128);
        let total_interest = (interest_per_sec * (period as u128)) + ((remainder * (period as u128)) / (seconds_in_year as u128));
        total_interest / 100
    }

    inline fun get_total_rewards_so_far(
        principal: u64,
        accumulated_rewards: u64,
        rewards_accumulated_at: u64,
        last_staked_time: u64,
        interest_rate: u64,
        seconds_in_year: u64,
        epoch_end_time: u64,
    ): u64 acquires StakePool, StakeApp {
        let rewards;
        let now = timestamp::now_seconds();
        if(now > epoch_end_time){
            now = epoch_end_time;
        };
        if (rewards_accumulated_at > 0) {
            rewards = ((accumulated_rewards as u128) + apply_reward_formula(
                principal,
                now - rewards_accumulated_at,
                interest_rate,
                seconds_in_year
            ));
        } else {
            rewards = apply_reward_formula(
                principal,
                now - last_staked_time,
                interest_rate,
                seconds_in_year
            );
        };
        (rewards as u64)
    }

    #[view]
    public fun expected_rewards(
        user_address: address,
        principal: u64,
    ): u64 acquires StakePool, UserInfo {
        let accumulated_rewards = 0;
        let now = timestamp::now_seconds();
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        if(exists<UserInfo>(user_address)) {
            accumulated_rewards = get_rewards_till_the_end_of_epoch(
                user_address,
                stake_pool_config.interest_rate,
                stake_pool_config.seconds_in_year,
                stake_pool_config.epoch_end_time,
            );
        };
        if(principal > 0) {
            let reward = apply_reward_formula(
                principal,
                stake_pool_config.epoch_end_time - now,
                stake_pool_config.interest_rate,
                stake_pool_config.seconds_in_year
            );
            accumulated_rewards = accumulated_rewards + (reward as u64);
        };
        accumulated_rewards
    }

    inline fun get_rewards_till_the_end_of_epoch(
        user_address: address,
        interest_rate: u64,
        seconds_in_year: u64,
        epoch_end_time: u64,
    ): u64 acquires UserInfo {
        let rewards;
        let user_config = borrow_global<UserInfo>(user_address);
        if (user_config.rewards_accumulated_at > 0) {
            rewards = ((user_config.accumulated_rewards as u128) + apply_reward_formula(
                user_config.principal,
                epoch_end_time - user_config.rewards_accumulated_at,
                interest_rate,
                seconds_in_year
            ));
        } else {
            rewards = apply_reward_formula(
                user_config.principal,
                epoch_end_time - user_config.last_staked_time,
                interest_rate,
                seconds_in_year
            );
        };
        (rewards as u64)
    }

    public entry fun claim_rewards<CoinType>(
        user: &signer,
    ) acquires StakeApp, ClaimPool, StakePool, UserInfo, RewardPool {
        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
        withdraw_rewards<CoinType>(user, &resource_signer);
    }

    #[test_only]
    public entry fun test_claim_stake<CoinType>(user:&signer, resource_signer: &signer) acquires StakePool, UserInfo, ClaimPool, RewardPool {
        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        withdraw_rewards<CoinType>(user, resource_signer);
    }

    public entry fun claim_principal_and_rewards<CoinType>(
        user: &signer,
    ) acquires StakeApp, ClaimPool, StakePool, UserInfo, RewardPool {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
        withdraw_principal_and_rewards<CoinType>(user, &resource_signer);
    }

    #[test_only]
    public entry fun test_claim_principal_and_rewards<CoinType>(user:&signer, resource_signer: &signer) acquires StakePool, UserInfo, ClaimPool, RewardPool {
        withdraw_principal_and_rewards<CoinType>(user, resource_signer);
    }

    inline fun withdraw_rewards<CoinType>(
        user: &signer,
        resource_signer: &signer,
    ) acquires ClaimPool, UserInfo, StakePool, RewardPool {
        let user_address = signer::address_of(user);
        assert!(exists<UserInfo>(user_address), error::permission_denied(E_NOT_STAKED_USER));
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        let user_state = borrow_global_mut<UserInfo>(user_address);
        let claim_state = borrow_global_mut<ClaimPool>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        let now = timestamp::now_seconds();

        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        assert!(now >= user_state.first_staked_time + SECONDS_IN_DAY, error::out_of_range(E_NOT_IN_CLAIMING_RANGE));
        assert!(reward_state.available_rewards > 0, error::resource_exhausted(E_REWARD_NOT_ENOUGH));

        let accumulated_rewards = get_total_rewards_so_far(
            user_state.principal,
            user_state.accumulated_rewards,
            user_state.rewards_accumulated_at,
            user_state.last_staked_time,
            stake_pool_config.interest_rate,
            stake_pool_config.seconds_in_year,
            stake_pool_config.epoch_end_time,
        );
        assert!(accumulated_rewards > 0 , error::unavailable(E_NOT_ENOUGH_REWARDS_TRY_AGAIN_LATER));

        let claimed_rewards = Table::borrow_mut_with_default(&mut claim_state.claimed_rewards, user_address, 0);
        *claimed_rewards = *claimed_rewards + accumulated_rewards;
        user_state.accumulated_rewards = 0;
        user_state.rewards_accumulated_at = timestamp::now_seconds();
        claim_state.total_claimed = claim_state.total_claimed + accumulated_rewards;
        reward_state.available_rewards = reward_state.available_rewards - accumulated_rewards;
        aptos_account::transfer_coins<CoinType>(resource_signer, user_address, accumulated_rewards);

        event::emit_event<ClaimRewardEvent>(
            &mut claim_state.update_total_claimed_events,
            ClaimRewardEvent {
                timestamp: now,
                claimed_amount: accumulated_rewards
            }
        );
    }

    inline fun withdraw_principal_and_rewards<CoinType>(
        user: &signer,
        resource_signer: &signer,
    ) acquires ClaimPool, UserInfo, StakePool, RewardPool {
        let user_address = signer::address_of(user);
        assert!(exists<UserInfo>(user_address), error::permission_denied(E_NOT_STAKED_USER));
        let now = timestamp::now_seconds();
        let user_state = borrow_global_mut<UserInfo>(user_address);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        let claim_state = borrow_global_mut<ClaimPool>(@propbase);

        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        assert!(reward_state.available_rewards > 0, error::resource_exhausted(E_REWARD_NOT_ENOUGH));
        assert!(!user_state.is_total_earnings_withdrawn, error::permission_denied(E_EARNINGS_ALREADY_WITHDRAWN));
        assert!(now > stake_pool_config.epoch_end_time, error::out_of_range(E_STAKE_IN_PROGRESS));

        let claimed_rewards = Table::borrow_mut_with_default(&mut claim_state.claimed_rewards, user_address, 0);
        let accumulated_rewards = get_total_rewards_so_far(
            user_state.principal,
            user_state.accumulated_rewards,
            user_state.rewards_accumulated_at,
            user_state.last_staked_time,
            stake_pool_config.interest_rate,
            stake_pool_config.seconds_in_year,
            stake_pool_config.epoch_end_time,
        );
        let principal = user_state.principal;
        let total_returns = principal + accumulated_rewards;
        *claimed_rewards = *claimed_rewards + accumulated_rewards;
        user_state.withdrawn = principal;
        user_state.accumulated_rewards = 0;
        user_state.is_total_earnings_withdrawn = true;
        user_state.rewards_accumulated_at = timestamp::now_seconds();
        reward_state.available_rewards = reward_state.available_rewards - accumulated_rewards;
        claim_state.total_claimed = claim_state.total_claimed + accumulated_rewards;
        aptos_account::transfer_coins<CoinType>(resource_signer, user_address, total_returns);

        event::emit_event<ClaimRewardEvent>(
            &mut claim_state.update_total_claimed_events,
            ClaimRewardEvent {
                timestamp: now,
                claimed_amount: accumulated_rewards
            }
        );
    }

    public entry fun withdraw_excess_rewards<CoinType>(
        treasury: &signer
    ) acquires RewardPool, StakePool, StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);

        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        assert!(signer::address_of(treasury) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));

        perform_withdraw_excess_rewards<CoinType>(&resource_signer, contract_config.treasury);
    }

    #[test_only]
    public entry fun test_withdraw_excess_rewards<CoinType>(treasury:&signer, resource_signer: &signer) acquires RewardPool, StakePool, StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
    
        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        assert!(signer::address_of(treasury) == contract_config.treasury, error::permission_denied(E_NOT_AUTHORIZED));
       
        perform_withdraw_excess_rewards<CoinType>(resource_signer, contract_config.treasury);
    }

    public entry fun withdraw_unclaimed_coins<CoinType>(
        treasury: &signer
    ) acquires RewardPool, StakePool, StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);

        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        assert!(signer::address_of(treasury) == contract_config.treasury, error::permission_denied(E_NOT_AUTHORIZED));

        perform_withdraw_unclaimed_coins<CoinType>(&resource_signer, contract_config.treasury);
    }

    #[test_only]
    public entry fun test_withdraw_unclaimed_coins<CoinType>(treasury:&signer, resource_signer: &signer) acquires RewardPool, StakePool, StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        
        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
        assert!(signer::address_of(treasury) == contract_config.treasury, error::permission_denied(E_NOT_AUTHORIZED));

        perform_withdraw_unclaimed_coins<CoinType>(resource_signer, contract_config.treasury);
    }

    inline fun perform_withdraw_unclaimed_coins<CoinType>(
        resource_signer: &signer,
        treasury: address,
    ) acquires RewardPool, StakePool {
        let now = timestamp::now_seconds();
        let contract_bal = coin::balance<CoinType>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        assert!(now > stake_pool_config.epoch_end_time, error::out_of_range(0));
        assert!(now > stake_pool_config.unclaimed_coin_withdraw_at, error::out_of_range(0));

        reward_state.available_rewards = 0;
        aptos_account::transfer_coins<CoinType>(resource_signer, treasury, contract_bal);
    }

    inline fun perform_withdraw_excess_rewards<CoinType>(
        resource_signer: &signer,
        treasury: address,
    ) {
        let now = timestamp::now_seconds();
        let contract_bal = get_contract_reward_balance<CoinType>();
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        let current_staked_amount = stake_pool_config.staked_amount;
        assert!(now > stake_pool_config.epoch_end_time, error::out_of_range(0));
        
        let calculated_required_funds = apply_reward_formula(
            current_staked_amount,
            stake_pool_config.epoch_end_time - stake_pool_config.epoch_start_time,
            stake_pool_config.interest_rate,
            stake_pool_config.seconds_in_year
        );
        let reward_to_return = contract_bal - (calculated_required_funds as u64);
        reward_state.available_rewards = reward_state.available_rewards - reward_to_return;
        aptos_account::transfer_coins<CoinType>(resource_signer, treasury, reward_to_return);
    }

    #[view]
    public fun get_app_config(
    ): (String, address, address, u64) acquires StakeApp {
        let staking_config = borrow_global<StakeApp>(@propbase);
        (staking_config.app_name, staking_config.admin, staking_config.treasury, staking_config.min_stake_amount)
    }

    #[view]
    public fun get_stake_pool_config(
    ): (u64, u64, u64, u64, u64, u64) acquires StakePool {
        let staking_pool_config = borrow_global<StakePool>(@propbase);
        (staking_pool_config.pool_cap, staking_pool_config.staked_amount, staking_pool_config.epoch_start_time, staking_pool_config.epoch_end_time, staking_pool_config.interest_rate, staking_pool_config.penalty_rate)
    }

    #[view]
    public fun check_is_reward_treasurers(
        user: address,
    ): bool acquires StakeApp {
        let staking_config = borrow_global<StakeApp>(@propbase);
        Table::contains(&staking_config.reward_treasurers, user)
    }

    #[view]
    public fun get_user_info(
        user: address
    ): (u64, u64, u64, u64, u64) acquires UserInfo {
        assert!(exists<UserInfo>(user), error::invalid_argument(E_NOT_STAKED_USER));
        let user_config = borrow_global<UserInfo>(user);
        return (
            user_config.principal,
            user_config.withdrawn,
            user_config.accumulated_rewards,
            user_config.rewards_accumulated_at,
            user_config.last_staked_time
        )
    }

    #[view]
    public fun get_principal_amount(
        user: address
    ): u64 acquires UserInfo {
        if(!account::exists_at(user) || !exists<UserInfo>(user)  ) {
            0
        } else {
            let user_config = borrow_global<UserInfo>(user);
            user_config.principal
        }
    }

    #[view]
    public fun get_unclaimed_coins_withdraw_at(
    ): u64 acquires StakePool {
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        stake_pool_config.unclaimed_coin_withdraw_at
    }

    #[view]
    public fun get_stake_amounts(
        user:address,
    ): vector<u64> acquires UserInfo {
        let amounts= vector::empty<u64>();
        if(!account::exists_at(user) || !exists<UserInfo>(user)  ) {
            amounts
        } else {
            let user_config = borrow_global<UserInfo>(user);
            let i = 0;
            let len = vector::length(&user_config.staked_items);

            while (i < len) {
                let element = vector::borrow(&user_config.staked_items, i);
                vector::push_back(&mut amounts, element.amount);
                i = i + 1; 
            };
            amounts
        }
    }

    #[view]
    public fun get_stake_time_stamps(
        user:address,
    ): vector<u64> acquires UserInfo {
        let timestamps= vector::empty<u64>();
        if(!account::exists_at(user) || !exists<UserInfo>(user)  ) {
            timestamps
        } else {
            let user_config = borrow_global<UserInfo>(user);
            let i = 0;
            let len = vector::length(&user_config.staked_items);

            while (i < len){
                let element = vector::borrow(&user_config.staked_items, i);
                vector::push_back(&mut timestamps, element.timestamp);
                i = i + 1;
            };
            timestamps
        }
    }

    #[view]
    public fun get_unstake_amounts(
        user:address,
    ): vector<u64> acquires UserInfo {
        let amounts= vector::empty<u64>();
        if(!account::exists_at(user) || !exists<UserInfo>(user)  ) {
            amounts
        } else {
            let user_config = borrow_global<UserInfo>(user);
            let i = 0;
            let len = vector::length(&user_config.unstaked_items);
            while (i < len){
                let element = vector::borrow(&user_config.unstaked_items, i);
                vector::push_back(&mut amounts, element.amount);
                i = i + 1; 
            };
            amounts
        }
    }

    #[view]
    public fun get_unstake_time_stamps(
        user:address,
    ): vector<u64> acquires UserInfo {
        let timestamps= vector::empty<u64>();
        if(!account::exists_at(user) || !exists<UserInfo>(user)  ) {
            timestamps
        } else {
            let user_config = borrow_global<UserInfo>(user);
            let i = 0;
            let len = vector::length(&user_config.unstaked_items);

            while (i < len){
                let element = vector::borrow(&user_config.unstaked_items, i);
                vector::push_back(&mut timestamps, element.timestamp);
                i = i + 1;
            };
            timestamps
        }
    }

    #[view]
    public fun get_current_rewards_earned(
        user: address,
    ): u64 acquires UserInfo, StakePool {
        if(!account::exists_at(user) || !exists<UserInfo>(user)  ) {
            0
        } else {
            let user_config = borrow_global<UserInfo>(user);
            let stake_pool_config = borrow_global<StakePool>(@propbase);

            get_total_rewards_so_far(
                user_config.principal,
                user_config.accumulated_rewards,
                user_config.rewards_accumulated_at,
                user_config.last_staked_time,
                stake_pool_config.interest_rate,
                stake_pool_config.seconds_in_year,
                stake_pool_config.epoch_end_time,
            )
        }
    }

    #[view]
    public fun get_rewards_claimed_by_user(
        user: address,
    ):u64 acquires ClaimPool {
        if(!account::exists_at(user) || !exists<UserInfo>(user)  ) {
            0
        } else {
            let claim_state = borrow_global<ClaimPool>(user);
            *Table::borrow(&claim_state.claimed_rewards, user)
        }
    }

    #[view]
    public fun get_contract_reward_balance<CoinType>(
    ): u64 acquires RewardPool {
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        reward_state.available_rewards
    }
}