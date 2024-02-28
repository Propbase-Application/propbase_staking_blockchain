// This module provides the foundation for all users to participate in staking $PROPS coin, unstaking and obtain $PROPS as rewards.
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
    use aptos_framework::aptos_account;
    use aptos_framework::account::{ Self, SignerCapability };
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;
    use aptos_framework::coin;

    struct StakeApp has key {
        app_name: String,
        signer_cap: account::SignerCapability,
        admin: address,
        treasury: address,
        reward_treasurer: address,
        min_stake_amount: u64,
        max_stake_amount: u64,
        emergency_locked: bool,
        excess_reward_calculated: bool,
        reward: u64,
        required_rewards: u64,
        excess_reward_calculated_addresses: vector<address>,
        epoch_emergency_stop_time: u64,
        emergency_asset_distributed_addressess: vector<address>,
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
        unclaimed_reward_withdraw_time: u64,
        unclaimed_reward_withdraw_at: u64,
        staked_addressess: vector<address>,
        exited_addressess: vector<address>,
        is_valid_state: bool,
    }

    struct RewardPool has key {
        available_rewards: u64,
    }

    struct ClaimPool has key {
        total_rewards_claimed: u64,
        total_claimed_principal: u64,
        claimed_rewards: TableWithLength<address, u64>,
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
    }

    #[event]
    struct StakeEvent has drop, store{
        principal: u64,
        amount: u64,
        accumulated_rewards: u64,
        staked_time: u64,
    }

    #[event]
    struct UnStakeEvent has drop, store{
        withdrawn: u64,
        amount: u64,
        penalty: u64,
        accumulated_rewards: u64,
        unstaked_time: u64,
    }

    #[event]
    struct Stake has drop, store {
        timestamp: u64,
        amount: u64,
    }

    #[event]
    struct ClaimRewardEvent has drop, store {
        timestamp: u64,
        claimed_amount: u64,
    }

    #[event]
    struct ClaimPrincipalAndRewardEvent has drop, store {
        timestamp: u64,
        claimed_amount: u64,
        reward_amount: u64,
    }

    #[event]
    struct SetAdminEvent has drop, store {
        old_admin: address,
        new_admin: address,
    }

    #[event]
    struct SetTreasuryEvent has drop, store {
        old_treasury: address,
        new_treasury: address,
    }

    #[event]
    struct SetRewardTreasurerEvent has drop, store {
        old_treasurer: address,
        new_treasurer: address,
    }

    #[event]
    struct UpdateRewardsEvent has drop, store {
        old_rewards: u64,
        new_rewards: u64,
    }

    #[event]
    struct SetStakePoolEvent has drop, store {
        pool_name: String,
        pool_cap: u64,
        epoch_start_time: u64,
        epoch_end_time: u64,
        interest_rate: u64,
        penalty_rate: u64,
        min_stake_amount: u64,
        max_stake_amount: u64,
        seconds_in_year: u64
    }

    #[event]
    struct EmergencyStopEvent has drop, store {
        time: u64,
        admin: address,
        emergency_locked: bool
    }

    #[event]
    struct SetExcessRewardCalculatedEvent has drop, store {
        required_rewards: u64,
        required_rewards_calculated: bool
    }

    #[event]
    struct EmergencyAssetDistributionEvent has drop, store {
        distributed_addressess: vector<address>,
        distributed_assets: vector<u64>
    }

    // Constants

    // The address of the PROPS coin is defined to be checked on coin transaction.
    const PROPS_COIN: vector<u8> = b"0x1::propbase_coin::PROPS";
    const SECONDS_IN_DAY: u64 = 86400;
    const SECONDS_IN_NON_LEAP_YEAR: u64 = 31536000;
    const SECONDS_IN_LEAP_YEAR: u64 = 31622400;
    const DEFAULT_REWARD_EXPIRY_TIME: u64 = 31536000 * 2;

    const E_NOT_AUTHORIZED: u64 = 1;
    const E_NOT_NOT_A_TREASURER: u64 = 2;
    const E_CONTRACT_ALREADY_EMERGENCY_LOCKED: u64 = 3;
    const E_STAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME: u64 = 4;
    const E_STAKE_POOL_EXHAUSTED: u64 = 5;
    const E_STAKE_ALREADY_STARTED: u64 = 6;
    const E_NOT_PROPS: u64 = 7;
    const E_INVALID_AMOUNT: u64 = 8;
    const E_NOT_IN_STAKING_RANGE: u64 = 9;
    const E_NOT_STAKED_USER: u64 = 10;
    const E_ACCOUNT_DOES_NOT_EXIST: u64 = 11;
    const E_STAKE_POOL_INTEREST_OUT_OF_RANGE: u64 = 12;
    const E_STAKE_POOL_PENALTY_OUT_OF_RANGE: u64 = 13;
    const E_STAKE_POOL_CAP_OUT_OF_RANGE: u64 = 14;     
    const E_STAKE_START_TIME_OUT_OF_RANGE: u64 = 15;
    const E_STAKE_END_TIME_OUT_OF_RANGE: u64 = 16;
    const E_STAKE_POOL_NAME_CANT_BE_EMPTY: u64 = 17;
    const E_AMOUNT_MUST_BE_GREATER_THAN_ZERO: u64 = 18;
    const E_REWARD_NOT_ENOUGH: u64 = 19;
    const E_AMOUNT_MUST_BE_GREATER_THAN_OR_EQUAL_TO_ONE: u64 = 20;
    const E_STAKE_NOT_ENOUGH: u64 = 21;
    const E_SECONDS_IN_YEAR_INVALID: u64 = 22;
    const E_NOT_ENOUGH_REWARDS_TRY_AGAIN_LATER: u64 = 23;
    const E_STAKE_IN_PROGRESS: u64 = 24;
    const E_NOT_IN_CLAIMING_RANGE: u64 = 25;
    const E_CONTRACT_EMERGENCY_LOCKED: u64 = 26;
    const E_EARNINGS_ALREADY_WITHDRAWN: u64 = 27;
    const E_INVALID_START_TIME: u64 = 28;
    const E_INVALID_MAX_STAKE_AMOUNT: u64 = 29;
    const E_USER_STAKE_LIMIT_REACHED: u64 = 30;
    const E_MAX_STAKE_MUST_BE_GREATER_THAN_MIN_STAKE: u64 = 31;
    const E_EXCESS_REWARD_NOT_CALCULATED: u64 = 32;
    const E_EXCESS_REWARD_ALREADY_CALCULATED: u64 = 33;
    const E_CONTRACT_NOT_EMERGENCY_LOCKED: u64 = 34;
    const E_CONTRACT_NOT_IN_VALID_STATE: u64 = 35;
    const E_IN_STAKING_RANGE: u64 = 36;
    const E_CLAIM_NOT_MATURED: u64 = 37;
    const E_ONE_DAY_NOT_PASSED_AFTER_FIRST_STAKE : u64 = 38;

    // This function is invoked automatically when the module is published.
    // Input: resource_account - resource account where the contract lives. This is passed by the publish command when its being deployed.
    fun init_module(resource_account: &signer) {
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_account, @source_addr);
        init_config(resource_account, resource_signer_cap);
    }

    // This function is invoked only when test is running. This enables us to test the contract for a resource account.
    // Input: resource_account - resource account where the contract lives for testing.
    #[test_only]
    public(friend) fun init_test(resource_account: &signer) {
        let resource_signer_cap = account::create_test_signer_cap(signer::address_of(resource_account));
        init_config(resource_account, resource_signer_cap);
    }

    // This function initialise the resources under resource_account.
    // Input: resource_account - resource account where the contract lives.
    // Input: resource_signer_cap - signer capability of resource account
    fun init_config(resource_account: &signer, resource_signer_cap: SignerCapability) {
        move_to(resource_account, StakeApp {
            app_name: string::utf8(b""),
            signer_cap: resource_signer_cap,
            admin: @source_addr,
            treasury: @source_addr,
            reward_treasurer: @source_addr,
            min_stake_amount: 0,
            max_stake_amount: 0,
            emergency_locked: false,
            excess_reward_calculated: false,
            reward: 0,
            required_rewards: 0,
            excess_reward_calculated_addresses: vector::empty<address>(),
            epoch_emergency_stop_time: 0,
            emergency_asset_distributed_addressess: vector::empty<address>(),
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
            unclaimed_reward_withdraw_time: DEFAULT_REWARD_EXPIRY_TIME,
            unclaimed_reward_withdraw_at: 0,
            staked_addressess: vector::empty<address>(),
            exited_addressess: vector::empty<address>(),
            is_valid_state: false,
        });
        move_to(resource_account, RewardPool {
            available_rewards: 0,
        });
        move_to(resource_account, ClaimPool {
            total_rewards_claimed: 0,
            total_claimed_principal: 0,
            claimed_rewards: Table::new(),
        });
    }
    
    // This function allows a current multisign admin to set a new multisign admin.
    // Input: admin - current admin account.
    // Input: new_admin_address - new multisign wallet address to be set as admin.
    public entry fun set_admin(
        admin: &signer,
        new_admin_address: address,
    ) acquires StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let old_admin = contract_config.admin;
        assert!(account::exists_at(new_admin_address), error::invalid_argument(E_ACCOUNT_DOES_NOT_EXIST));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));

        contract_config.admin = new_admin_address;

        let setAdminEvent = SetAdminEvent {
                old_admin: old_admin,
                new_admin: new_admin_address
            };  
        event::emit(setAdminEvent);
    }

    // This function allows a current admin to set a new multisign treasury.
    // Input: admin - current admin account.
    // Input: new_treasury_address - new multisign wallet address to be set as treasury.
    public entry fun set_treasury(
        admin: &signer,
        new_treasury_address: address,
    ) acquires StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let old_treasury = contract_config.treasury;
        assert!(account::exists_at(new_treasury_address), error::invalid_argument(E_ACCOUNT_DOES_NOT_EXIST));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));

        contract_config.treasury = new_treasury_address;

        let setTreasuryEvent = SetTreasuryEvent {
                old_treasury: old_treasury,
                new_treasury: new_treasury_address
            };
        event::emit(setTreasuryEvent);
    }

    // This function allows a current admin to set a new multisign reward treasury.
    // Input: admin - current admin account.
    // Input: new_treasurer - new multisign wallet address to be set as reward treasury.
    public entry fun set_reward_treasurer(
        admin: &signer,
        new_treasurer: address,
    ) acquires StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let old_treasurer = contract_config.reward_treasurer;
        assert!(account::exists_at(new_treasurer), error::invalid_argument(E_ACCOUNT_DOES_NOT_EXIST));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));

        contract_config.reward_treasurer = new_treasurer;

        let setRewardTreasurerEvent = SetRewardTreasurerEvent {
                old_treasurer: old_treasurer,
                new_treasurer: new_treasurer
            };
        event::emit(setRewardTreasurerEvent);
    }

    // This function sets the contract configurations for pool
    // Input: admin - admin account
    // Input: pool_name - name of the pool.
    // Input: pool_cap - maximum limit of the PROPS that can be staked in the pool from all users.
    // Input: epoch_start_time - UNIX timestamp of pool start time.
    // Input: epoch_end_time - UNIX timestamp of pool end time.
    // Input: interest_rate - APY value of the pool at which rewards are calculated.
    // Input: penalty_rate - fee percentage applied when a user unstakes.
    // Input: min_stake_amount - minimum PROPS that can be staked in a single stake action.
    // Input: max_stake_amount - maximum PROPS that can be staked in a single stake action.
    // Input: seconds_in_year - seconds in 365 days or 366 days based on pool start time.
    // Input: value_config - array of boolean configs.
    public entry fun create_or_update_stake_pool(
        admin: &signer,
        pool_name: String,
        pool_cap: u64,
        epoch_start_time: u64,
        epoch_end_time: u64,
        interest_rate: u64,
        penalty_rate: u64,
        min_stake_amount: u64,
        max_stake_amount: u64,
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
        let set_max_stake_amount = *vector::borrow(&value_config, 7);
        let set_seconds_in_year = *vector::borrow(&value_config, 8);

        if(set_epoch_start_time && set_epoch_end_time) {
            assert!(epoch_start_time < epoch_end_time, error::invalid_argument(E_STAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
        };
        if(set_pool_cap) {
            assert!(pool_cap >= 20000000000, error::invalid_argument(E_STAKE_POOL_CAP_OUT_OF_RANGE));
            stake_pool_config.pool_cap = pool_cap;          
        };
        if(set_epoch_start_time) {
            assert!(epoch_start_time > 0, error::invalid_argument(E_STAKE_START_TIME_OUT_OF_RANGE));
            assert!(epoch_start_time < stake_pool_config.epoch_end_time || stake_pool_config.epoch_end_time == 0, error::invalid_argument(E_STAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
            assert!(timestamp::now_seconds() <= epoch_start_time, error::invalid_argument(E_INVALID_START_TIME));
            stake_pool_config.epoch_start_time = epoch_start_time; 
        };
        if(set_epoch_end_time) {
            assert!(epoch_end_time > 0, error::invalid_argument(E_STAKE_END_TIME_OUT_OF_RANGE));
            assert!(epoch_end_time > stake_pool_config.epoch_start_time, error::invalid_argument(E_STAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
            stake_pool_config.epoch_end_time = epoch_end_time;
            stake_pool_config.unclaimed_reward_withdraw_at = epoch_end_time + stake_pool_config.unclaimed_reward_withdraw_time;
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
            assert!(min_stake_amount >= 100000000, error::invalid_argument(E_AMOUNT_MUST_BE_GREATER_THAN_OR_EQUAL_TO_ONE));
            contract_config.min_stake_amount = min_stake_amount;
        };
        if(set_max_stake_amount) {
            assert!(max_stake_amount > contract_config.min_stake_amount, error::invalid_argument(E_MAX_STAKE_MUST_BE_GREATER_THAN_MIN_STAKE));
            assert!(max_stake_amount <= stake_pool_config.pool_cap / 2, error::invalid_argument(E_INVALID_MAX_STAKE_AMOUNT));
            contract_config.max_stake_amount = max_stake_amount;
        };
        if(set_seconds_in_year) {
            assert!(seconds_in_year == SECONDS_IN_NON_LEAP_YEAR || seconds_in_year == SECONDS_IN_LEAP_YEAR, error::invalid_argument(E_SECONDS_IN_YEAR_INVALID));
            stake_pool_config.seconds_in_year = seconds_in_year;
        };

        let period = stake_pool_config.epoch_end_time - stake_pool_config.epoch_start_time;
        let required_rewards = apply_reward_formula(stake_pool_config.pool_cap, period, stake_pool_config.interest_rate, stake_pool_config.seconds_in_year);
        assert!(reward_state.available_rewards >= (required_rewards as u64), error::resource_exhausted(E_REWARD_NOT_ENOUGH));
        validate_state(stake_pool_config);

        let setStakePoolEvent = SetStakePoolEvent {
                pool_name: contract_config.app_name,
                pool_cap: stake_pool_config.pool_cap,
                epoch_start_time: stake_pool_config.epoch_start_time,
                epoch_end_time: stake_pool_config.epoch_end_time,
                interest_rate: stake_pool_config.interest_rate,
                penalty_rate: stake_pool_config.penalty_rate,
                min_stake_amount: contract_config.min_stake_amount,
                max_stake_amount: contract_config.max_stake_amount,
                seconds_in_year: stake_pool_config.seconds_in_year
            };
        event::emit(setStakePoolEvent);
    }

    // This function adds more time to default reward expiry time. 
    // Reward expiry time is time after which the rewards that are unclaimed by the user is withdrawn by treasury.
    // Input: admin - admin account
    // Input: additional_time - time in seconds that needs to be added
    public entry fun set_reward_expiry_time(
        admin: &signer,
        additional_time: u64,
    ) acquires StakeApp, StakePool {
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        assert!(stake_pool_config.is_valid_state, error::permission_denied(E_CONTRACT_NOT_IN_VALID_STATE));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        stake_pool_config.unclaimed_reward_withdraw_time = DEFAULT_REWARD_EXPIRY_TIME + additional_time;
        stake_pool_config.unclaimed_reward_withdraw_at = stake_pool_config.epoch_end_time + stake_pool_config.unclaimed_reward_withdraw_time;
    }

    // This function allows users to stake $PROPS in the contract within the staking period 
    // Input: user - user account
    // Input: amount - $PROPS amount to stake 
    public entry fun add_stake<CoinType> (
        user: &signer,
        amount: u64
    ) acquires  UserInfo, StakePool, StakeApp {
        let now = timestamp::now_seconds();
        let user_address = signer::address_of(user);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let contract_config = borrow_global_mut<StakeApp>(@propbase);

        assert!(stake_pool_config.is_valid_state, error::permission_denied(E_CONTRACT_NOT_IN_VALID_STATE));
        assert!(!contract_config.emergency_locked, error::invalid_state(E_CONTRACT_EMERGENCY_LOCKED));
        assert_props<CoinType>();
        assert!(amount >= contract_config.min_stake_amount, error::invalid_argument(E_INVALID_AMOUNT));
        assert!(now >= stake_pool_config.epoch_start_time && now < stake_pool_config.epoch_end_time, error::out_of_range(E_NOT_IN_STAKING_RANGE));
        assert!(now < stake_pool_config.epoch_end_time - SECONDS_IN_DAY, error::out_of_range(E_NOT_IN_STAKING_RANGE));
        assert!(stake_pool_config.staked_amount + amount <= stake_pool_config.pool_cap, error::resource_exhausted(E_STAKE_POOL_EXHAUSTED));

        stake_pool_config.staked_amount = stake_pool_config.staked_amount + amount;
        if (!vector::contains(&mut stake_pool_config.staked_addressess, &user_address)) {
            vector::push_back(&mut stake_pool_config.staked_addressess, user_address);
        };
        aptos_account::transfer_coins<CoinType>(user, @propbase, amount);

        if(!exists<UserInfo>(user_address)) {
            let stake_buffer = vector::empty<Stake>();
            let unstake_buffer = vector::empty<Stake>();
            assert!(amount <= contract_config.max_stake_amount, error::resource_exhausted(E_USER_STAKE_LIMIT_REACHED));
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
            });

            let user_state = borrow_global_mut<UserInfo>(user_address);

            let stake_events = StakeEvent {
                    principal: amount,
                    amount: amount,
                    accumulated_rewards: 0,
                    staked_time: now,
                };
            event::emit(stake_events);
        } else {
            let user_state = borrow_global_mut<UserInfo>(user_address);
            assert!(user_state.principal + amount <= contract_config.max_stake_amount, error::resource_exhausted(E_USER_STAKE_LIMIT_REACHED));
            let accumulated_rewards = get_total_rewards_so_far(
                user_state.principal,
                user_state.accumulated_rewards,
                user_state.rewards_accumulated_at,
                user_state.last_staked_time,
                stake_pool_config.interest_rate,
                stake_pool_config.seconds_in_year,
                stake_pool_config.epoch_end_time,
                contract_config.epoch_emergency_stop_time
            );

            user_state.accumulated_rewards = (accumulated_rewards as u64);
            user_state.principal = user_state.principal + amount;
            user_state.last_staked_time = now;
            user_state.rewards_accumulated_at = now;
            vector::push_back(&mut user_state.staked_items, Stake { timestamp: now, amount });

            let stake_events = StakeEvent {
                    principal: user_state.principal,
                    amount: amount,
                    accumulated_rewards: user_state.accumulated_rewards,
                    staked_time: now,
                };
            event::emit(stake_events);
        }
    }

    // This function allows users to unstake $PROPS in the contract within the staking period with a penalty on principal
    // Input: user - user account
    // Input: amount - $PROPS amount to unstake 
    public entry fun withdraw_stake<CoinType> (
        user: &signer,
        amount: u64
    ) acquires UserInfo, StakeApp, StakePool {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
        implement_unstake<CoinType>(user, &resource_signer, amount);
    }

    // This is helper function for withdrawing stake
    // Input: user - user account
    // Input: resource_signer - resource signer where the contract lives
    // Input: amount - $PROPS amount to unstake
    inline fun implement_unstake<CoinType>(
        user: &signer,
        resource_signer: &signer,
        amount: u64,
    ) acquires UserInfo, StakePool, StakeApp {
        let user_address = signer::address_of(user);
        assert!(exists<UserInfo>(user_address), error::permission_denied(E_NOT_STAKED_USER));
        assert_props<CoinType>();

        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let now = timestamp::now_seconds();
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let user_state = borrow_global_mut<UserInfo>(user_address);

        assert!(!contract_config.emergency_locked, error::invalid_state(E_CONTRACT_EMERGENCY_LOCKED));
        assert!(now <= stake_pool_config.epoch_end_time, error::out_of_range(E_NOT_IN_STAKING_RANGE));
        assert!(amount >= 100000000, error::invalid_argument(E_AMOUNT_MUST_BE_GREATER_THAN_OR_EQUAL_TO_ONE));
        assert!(now >= user_state.first_staked_time + SECONDS_IN_DAY, error::out_of_range(E_ONE_DAY_NOT_PASSED_AFTER_FIRST_STAKE));
        assert!(user_state.principal >= amount, error::resource_exhausted(E_STAKE_NOT_ENOUGH));

        let accumulated_rewards = get_total_rewards_so_far(
            user_state.principal,
            user_state.accumulated_rewards,
            user_state.rewards_accumulated_at,
            user_state.last_staked_time,
            stake_pool_config.interest_rate,
            stake_pool_config.seconds_in_year,
            stake_pool_config.epoch_end_time,
            contract_config.epoch_emergency_stop_time
        );
        stake_pool_config.staked_amount = stake_pool_config.staked_amount - amount;
        user_state.accumulated_rewards = (accumulated_rewards as u64);
        user_state.rewards_accumulated_at = now;
        user_state.principal = user_state.principal - amount;
        user_state.withdrawn = user_state.withdrawn + amount;

        vector::push_back(&mut user_state.unstaked_items, Stake { timestamp: now, amount });
        let penalty = amount / 100 * stake_pool_config.penalty_rate;
        let bal_after_penalty = amount - penalty;
        stake_pool_config.total_penalty = stake_pool_config.total_penalty + penalty;

        aptos_account::transfer_coins<CoinType>(resource_signer, contract_config.treasury, penalty);
        aptos_account::transfer_coins<CoinType>(resource_signer, user_address, bal_after_penalty);

        if (user_state.principal == 0) {
            update_addresses_on_exit(stake_pool_config, user_address);
        };

        let unstake_events = UnStakeEvent {
                withdrawn: user_state.withdrawn,
                amount: amount,
                penalty: penalty,
                accumulated_rewards: user_state.accumulated_rewards,
                unstaked_time: now,
            };
        event::emit(unstake_events);
    }

    // This function removes the given address from staked_addressess and adds to exited_addressess
    // Input: stake_pool_config - StakePool
    // Input: user_address - address of the user
    inline fun update_addresses_on_exit(
        stake_pool_config: &mut StakePool,
        user_address: address
    ) {
        if (vector::contains(&mut stake_pool_config.staked_addressess, &user_address)) {
            let (exists, index) = vector::index_of(&stake_pool_config.staked_addressess, &user_address);
            if (exists) {
                vector::remove(&mut stake_pool_config.staked_addressess, index);
                if (!vector::contains(&mut stake_pool_config.exited_addressess, &user_address)) {
                    vector::push_back(&mut stake_pool_config.exited_addressess, user_address);
                };
            }
        };
    }

    // This function allows reward treasurer account to add reward funds to the contract.
    // Input: treasurer - reward treasurer account.
    // Input: amount - $PROPS amount to add as reward.
    public entry fun add_reward_funds<CoinType>(
        treasurer: &signer,
        amount: u64,
    ) acquires StakeApp, RewardPool, StakePool {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        assert!(!contract_config.emergency_locked, error::invalid_state(E_CONTRACT_EMERGENCY_LOCKED));
        assert!(amount > 0, error::invalid_argument(E_AMOUNT_MUST_BE_GREATER_THAN_ZERO));
        assert_props<CoinType>();
        assert!(contract_config.reward_treasurer == signer::address_of(treasurer), error::permission_denied(E_NOT_NOT_A_TREASURER));
        assert!((timestamp::now_seconds() < stake_pool_config.epoch_start_time) || stake_pool_config.epoch_start_time == 0, error::permission_denied(E_STAKE_ALREADY_STARTED));
        let prev_reward = reward_state.available_rewards;
        let updated_reward = prev_reward + amount;
        reward_state.available_rewards = updated_reward;
        contract_config.reward = updated_reward;
        aptos_account::transfer_coins<CoinType>(treasurer, @propbase, amount);

        let updated_rewards_events = UpdateRewardsEvent {
                old_rewards: prev_reward,
                new_rewards: updated_reward
            };
        event::emit(updated_rewards_events);
    }

    // This function is a helper function that calculates the rewards
    // Rewards = Principal * Number of Years (Period) * Rate / 100
    // Input: principal - principal amount
    // Input: period - duration in seconds for a period
    // Input: interest_rate - APY%
    // Input: seconds_in_year - seconds in 365 days or 366 days
    // Output: rewards - returns the rewards based on inputs
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

    // This function is a helper function that calculates the accumulated rewards.
    // Rewards are calculated and summed up whenever user stakes, unstakes and claim rewards.
    // Input: principal - principal staked amount
    // Input: accumulated_rewards - rewards accumulated till now
    // Input: rewards_accumulated_at - last accumulation time
    // Input: last_staked_time - last user staked timestamp in UNIX time
    // Input: interest_rate - APY % 
    // Input: seconds_in_year - seconds in 365 days or 366 days
    // Input: epoch_end_time - end time of epoch
    // Input: epoch_emergency_stop_time - in case of emergency, emergency declared time is used as end time
    // Output: rewards - returns the rewards based on inputs
    inline fun get_total_rewards_so_far(
        principal: u64,
        accumulated_rewards: u64,
        rewards_accumulated_at: u64,
        last_staked_time: u64,
        interest_rate: u64,
        seconds_in_year: u64,
        epoch_end_time: u64,
        epoch_emergency_stop_time: u64
    ): u64 acquires StakePool, StakeApp {
        let rewards;
        let now = timestamp::now_seconds();
        if(now > epoch_end_time) {
            now = epoch_end_time;
        };
        if(epoch_emergency_stop_time > 0 && now > epoch_emergency_stop_time) {
            now = epoch_emergency_stop_time;
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

    // This function is a helper function that calculates the expected rewards if user kept the stake till end of pool.
    // Input: user_address - user address for which rewards are needed to be calculated
    // Input: interest_rate - contract interest rate in %APY
    // Input: seconds_in_year - seconds in 365 days or 366 days
    // Input: epoch_end_time - pool end time in UNIX timestamp
    // Output: rewards - calculated rewards
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

    // This function is invoked by user to collect rewards for their $PROPS invested in pool.
    // Input: user - user account
    public entry fun claim_rewards<CoinType>(
        user: &signer,
    ) acquires StakeApp, ClaimPool, StakePool, UserInfo, RewardPool {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
        withdraw_rewards<CoinType>(user, &resource_signer);
    }

    // This function is invoked by user to collect rewards & principal for their $PROPS invested in pool.
    // Input: user - user account
    public entry fun claim_principal_and_rewards<CoinType>(
        user: &signer,
    ) acquires StakeApp, ClaimPool, StakePool, UserInfo, RewardPool {
        withdraw_principal_and_rewards<CoinType>(user);
    }

    // This function is invoked by admin to declare emergency.
    // After which user cannot invoke any functions.
    // Input: admin - admin account
    public entry fun emergency_stop(
        admin: &signer
    ) acquires StakeApp, StakePool {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let now = timestamp::now_seconds();
        let admin_address = signer::address_of(admin);

        assert!(now < stake_pool_config.epoch_end_time, error::out_of_range(E_NOT_IN_STAKING_RANGE));
        assert!(admin_address == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(!contract_config.emergency_locked, error::invalid_argument(E_CONTRACT_ALREADY_EMERGENCY_LOCKED));

        contract_config.emergency_locked = true;
        contract_config.epoch_emergency_stop_time = now;
        let emergency_stop_events = EmergencyStopEvent {
                time: now,
                admin: admin_address,
                emergency_locked: contract_config.emergency_locked
            };
        event::emit(emergency_stop_events);
    }

    // This function is used by admin to distritbute user staked $PROPS and rewards $PROPS to user.
    // This function needs to be called as many times possible to cover all the users.
    // Input: admin - admin account
    // Input: user_limit - number of users to process distribution
    public entry fun emergency_asset_distribution<CoinType>(
        admin: &signer,
        user_limit: u8,
    ) acquires UserInfo, StakeApp, StakePool, RewardPool, ClaimPool {
        assert_props<CoinType>();
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        let claim_state = borrow_global_mut<ClaimPool>(@propbase);
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(contract_config.emergency_locked, error::invalid_state(E_CONTRACT_NOT_EMERGENCY_LOCKED));
        let contract_balance = coin::balance<CoinType>(@propbase);
        assert!(contract_balance > 0, error::permission_denied(E_EARNINGS_ALREADY_WITHDRAWN));

        let distributed_addressess_length = vector::length(&contract_config.emergency_asset_distributed_addressess);
        let length = vector::length(&stake_pool_config.staked_addressess);
        let limit = 20;
        if (user_limit > 0) {
            limit = user_limit;
        };
        let index = distributed_addressess_length;
        let i = 0;
        let distributed_addressess = vector::empty<address>();
        let distributed_assets = vector::empty<u64>();
        while (length > 0 && index < length && i < (limit as u64)) {
            let user = *vector::borrow(&stake_pool_config.staked_addressess, index);
            let user_state = borrow_global_mut<UserInfo>(user);
            let (total_returns, _) = transfer_principal_and_rewards<CoinType>(
                user,
                user_state,
                contract_config,
                stake_pool_config,
                reward_state,
                claim_state,
                true
            );
            vector::push_back(&mut contract_config.emergency_asset_distributed_addressess, user);
            vector::push_back(&mut distributed_addressess, user);
            vector::push_back(&mut distributed_assets, total_returns);
            index = index + 1;
            i = i + 1;
        };
        if (index == length) {
            let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
            let contract_balance_new = coin::balance<CoinType>(@propbase);
            aptos_account::transfer_coins<CoinType>(&resource_signer, contract_config.treasury, contract_balance_new);
            reward_state.available_rewards = 0;
        };

        let emergency_asset_distribution_events = EmergencyAssetDistributionEvent {
                distributed_addressess: distributed_addressess,
                distributed_assets: distributed_assets
            };
        event::emit(emergency_asset_distribution_events);
    }

    // This function is a helper function this is used by user to claim $PROPS rewards
    // Input: user - user account
    // Input: resource_signer - resource signer where the contract lives
    inline fun withdraw_rewards<CoinType>(
        user: &signer,
        resource_signer: &signer,
    ) acquires ClaimPool, UserInfo, StakePool, RewardPool, StakeApp {
        let user_address = signer::address_of(user);
        assert!(exists<UserInfo>(user_address), error::permission_denied(E_NOT_STAKED_USER));
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        let user_state = borrow_global_mut<UserInfo>(user_address);
        let claim_state = borrow_global_mut<ClaimPool>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        let now = timestamp::now_seconds();

        assert!(!contract_config.emergency_locked, error::invalid_state(E_CONTRACT_EMERGENCY_LOCKED));
        assert!(now <= stake_pool_config.epoch_end_time, error::out_of_range(E_NOT_IN_STAKING_RANGE));
        assert_props<CoinType>();
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
            contract_config.epoch_emergency_stop_time
        );
        assert!(accumulated_rewards > 0, error::unavailable(E_NOT_ENOUGH_REWARDS_TRY_AGAIN_LATER));

        let claimed_rewards = Table::borrow_mut_with_default(&mut claim_state.claimed_rewards, user_address, 0);
        *claimed_rewards = *claimed_rewards + accumulated_rewards;
        user_state.accumulated_rewards = 0;
        user_state.rewards_accumulated_at = timestamp::now_seconds();
        claim_state.total_rewards_claimed = claim_state.total_rewards_claimed + accumulated_rewards;
        reward_state.available_rewards = reward_state.available_rewards - accumulated_rewards;
        aptos_account::transfer_coins<CoinType>(resource_signer, user_address, accumulated_rewards);

        let claim_reward_events = ClaimRewardEvent {
                timestamp: now,
                claimed_amount: accumulated_rewards
            };
        event::emit(claim_reward_events);
    }

    // This function is a helper function this is used by user to claim principal and rewards 
    // Input: user - user account
    inline fun withdraw_principal_and_rewards<CoinType>(
        user: &signer
    ) acquires ClaimPool, UserInfo, StakePool, RewardPool, StakeApp {
        let user_address = signer::address_of(user);
        assert!(exists<UserInfo>(user_address), error::permission_denied(E_NOT_STAKED_USER));
        let now = timestamp::now_seconds();
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let user_state = borrow_global_mut<UserInfo>(user_address);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let claim_state = borrow_global_mut<ClaimPool>(@propbase);

        assert!(!contract_config.emergency_locked, error::invalid_state(E_CONTRACT_EMERGENCY_LOCKED));
        assert_props<CoinType>();
        assert!(!user_state.is_total_earnings_withdrawn, error::permission_denied(E_EARNINGS_ALREADY_WITHDRAWN));
        assert!(now > stake_pool_config.epoch_end_time, error::out_of_range(E_STAKE_IN_PROGRESS));
        let (total_returns, accumulated_rewards) = transfer_principal_and_rewards<CoinType>(
            user_address,
            user_state,
            contract_config,
            stake_pool_config,
            reward_state,
            claim_state,
            false
        );
        update_addresses_on_exit(stake_pool_config, user_address);

        let updated_claim_principal_and_reward_events = ClaimPrincipalAndRewardEvent {
                timestamp: now,
                claimed_amount: total_returns,
                reward_amount: accumulated_rewards
            };
        event::emit(updated_claim_principal_and_reward_events);
    }

    // This function is a helper function this is used to transfer $PROPS from contract to user_address 
    // Input: user_address - user account address
    // Input: user_state - UserInfo
    // Input: contract_config - StakeApp
    // Input: stake_pool_config - StakePool
    // Input: reward_state - RewardPool
    // Input: claim_state - ClaimPool
    // Input: is_batch - flag to identify if its a batchwise transaction or not.
    // Output: total_returns - total principal and rewards
    // Output: accumulated_rewards - rewards accumulated
    fun transfer_principal_and_rewards<CoinType>(
        user_address: address,
        user_state: &mut UserInfo,
        contract_config: &mut StakeApp,
        stake_pool_config: &mut StakePool,
        reward_state: &mut RewardPool,
        claim_state: &mut ClaimPool,
        is_batch: bool
    ): (u64, u64) {
        let claimed_rewards = Table::borrow_mut_with_default(&mut claim_state.claimed_rewards, user_address, 0);
        let accumulated_rewards = get_total_rewards_so_far(
            user_state.principal,
            user_state.accumulated_rewards,
            user_state.rewards_accumulated_at,
            user_state.last_staked_time,
            stake_pool_config.interest_rate,
            stake_pool_config.seconds_in_year,
            stake_pool_config.epoch_end_time,
            contract_config.epoch_emergency_stop_time
        );
        if (reward_state.available_rewards == 0) {
            accumulated_rewards = 0;
        };
        let principal = user_state.principal;
        let total_returns = principal + accumulated_rewards;
        if (is_batch && total_returns <= 0) {
            return (0, 0)
        };
        assert!(total_returns > 0, error::permission_denied(E_EARNINGS_ALREADY_WITHDRAWN));
        *claimed_rewards = *claimed_rewards + accumulated_rewards;
        user_state.withdrawn = user_state.withdrawn + principal;
        user_state.accumulated_rewards = 0;
        user_state.is_total_earnings_withdrawn = true;
        reward_state.available_rewards = reward_state.available_rewards - accumulated_rewards;
        claim_state.total_rewards_claimed = claim_state.total_rewards_claimed + accumulated_rewards;
        claim_state.total_claimed_principal = claim_state.total_claimed_principal + principal;
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
        aptos_account::transfer_coins<CoinType>(&resource_signer, user_address, total_returns);
        return (total_returns, accumulated_rewards)
    }

    // This function is a helper function this is used to check CoinType 
    // Input: none
    inline fun assert_props<CoinType>(){
        assert!(type_info::type_name<CoinType>() == string::utf8(PROPS_COIN), error::invalid_argument(E_NOT_PROPS));
    }

    // This function is used by treasuy to withdraw excess rewards.
    // When pools ends, we can determine the exact reward that needs to be distributed.
    // When required rewards of all users are calculated, then treasury can withdraw the excess rewards.
    // Input: treasury - treasury account
    public entry fun withdraw_excess_rewards<CoinType>(
        treasury: &signer
    ) acquires RewardPool, StakePool, StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
        perform_withdraw_excess_rewards<CoinType>(treasury, &resource_signer);
    }

    // This function is a helper function this is used by treasury to withdraw excess rewards
    // Input: user - user account
    // Input: resource_signer - resource signer where the contract lives
    inline fun perform_withdraw_excess_rewards<CoinType>(
        user: &signer,
        resource_signer: &signer,
    ) {
        let now = timestamp::now_seconds();
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global<StakePool>(@propbase);

        assert!(stake_pool_config.is_valid_state, error::permission_denied(E_CONTRACT_NOT_IN_VALID_STATE));
        assert!(!contract_config.emergency_locked, error::invalid_state(E_CONTRACT_EMERGENCY_LOCKED));
        assert_props<CoinType>();
        assert!(signer::address_of(user) == contract_config.treasury, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(now > stake_pool_config.epoch_end_time, error::out_of_range(E_IN_STAKING_RANGE));
        assert!(contract_config.excess_reward_calculated, error::permission_denied(E_EXCESS_REWARD_NOT_CALCULATED));

        let reward_balance = get_contract_reward_balance();
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        let excess = reward_balance - contract_config.required_rewards;
        reward_state.available_rewards = reward_state.available_rewards - excess;
        aptos_account::transfer_coins<CoinType>(resource_signer, contract_config.treasury, excess);
    }

    // This function is a helper function this is used to calculate required rewards before withdrawing excess rewards.
    // When pools ends, admin or treasury can use this function to determine the exact reward that needs to be distributed.
    // From this excess reward can be calculated.
    // This function needs to be called as many times as needed to cover all users.
    // Input: user - user account
    // Input: user_limit - number of users for which rewards are to be calculated.
    public entry fun calculate_required_rewards(
        user: &signer,  
        user_limit: u8,     
    ) acquires StakeApp, StakePool, UserInfo {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        let now = timestamp::now_seconds();

        assert!(signer::address_of(user) == contract_config.treasury || signer::address_of(user) == contract_config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(now > stake_pool_config.epoch_end_time, error::out_of_range(E_STAKE_IN_PROGRESS));
        assert!(!contract_config.excess_reward_calculated, error::invalid_argument(E_EXCESS_REWARD_ALREADY_CALCULATED));

        let index = vector::length(&contract_config.excess_reward_calculated_addresses);
        let length = vector::length(&stake_pool_config.staked_addressess);
        let limit = 20;
        if(user_limit > 0) {
            limit = user_limit;
        };
        let i = 0;
        while (length > 0 && index < length && i < (limit as u64)) {
            let user_addr = *vector::borrow(&stake_pool_config.staked_addressess, index);
            let user_state = borrow_global<UserInfo>(user_addr);
            let rewards = 0;
            if(!user_state.is_total_earnings_withdrawn) {
                vector::push_back(&mut contract_config.excess_reward_calculated_addresses, user_addr);
                rewards = get_total_rewards_so_far(
                    user_state.principal,
                    user_state.accumulated_rewards,
                    user_state.rewards_accumulated_at,
                    user_state.last_staked_time,
                    stake_pool_config.interest_rate,
                    stake_pool_config.seconds_in_year,
                    stake_pool_config.epoch_end_time,
                    contract_config.epoch_emergency_stop_time
                );
            };
            contract_config.required_rewards = contract_config.required_rewards + rewards;
            index = index + 1;
            i = i + 1;
        };

        if (index == length) {
            contract_config.excess_reward_calculated = true;

            let set_excess_reward_calculated_event = SetExcessRewardCalculatedEvent {
                    required_rewards: contract_config.required_rewards,
                    required_rewards_calculated: true,
                };
            event::emit(set_excess_reward_calculated_event);
        };
    }

    // This function is used by treasuy to withdraw unclaimed rewards after reward claim time is expired.
    // Input: treasury - treasury account
    public entry fun withdraw_unclaimed_rewards<CoinType>(
        treasury: &signer
    ) acquires RewardPool, StakePool, StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let resource_signer = account::create_signer_with_capability(&contract_config.signer_cap);
        perform_withdraw_unclaimed_rewards<CoinType>(treasury, &resource_signer);
    }

    // This function is a helper function this is used to transfer unclaimed $PROPS rewards to treasury
    // Input: user - treasury account
    // Input: resource_signer - resource signer where the contract lives
    inline fun perform_withdraw_unclaimed_rewards<CoinType>(
        user: &signer,
        resource_signer: &signer,
    ) acquires RewardPool, StakePool {
        let now = timestamp::now_seconds();
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let reward_balance = get_contract_reward_balance();
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let reward_state = borrow_global_mut<RewardPool>(@propbase);
        assert!(!contract_config.emergency_locked, error::invalid_state(E_CONTRACT_EMERGENCY_LOCKED));
        assert_props<CoinType>();
        assert!(signer::address_of(user) == contract_config.treasury, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(now > stake_pool_config.unclaimed_reward_withdraw_at, error::out_of_range(E_CLAIM_NOT_MATURED));

        reward_state.available_rewards = 0;
        aptos_account::transfer_coins<CoinType>(resource_signer, contract_config.treasury, reward_balance);
    }

    inline fun validate_state(
        stake_pool_config: &mut StakePool
    ){
        if(stake_pool_config.pool_cap >= 20000000000 && stake_pool_config.epoch_start_time > 0 && stake_pool_config.epoch_end_time > 0 && 
        stake_pool_config.epoch_start_time < stake_pool_config.epoch_end_time && stake_pool_config.interest_rate > 0 && stake_pool_config.penalty_rate > 0){
            stake_pool_config.is_valid_state = true;
        }
    }

    // This function is a view function that shows StakeApp variables at given time.
    // Input: none
    // Output: app_name - pool name
    // Output: admin - admin address
    // Output: treasury -treasury address
    // Output: reward_treasurer - reward treasurer address
    // Output: min_stake_amount - minimum $PROPS that can be staked in a single stake action.
    // Output: max_stake_amount - maximum $PROPS that can be staked in a single stake action.
    // Output: emergency_locked - flag to track if an emergency is declared.
    // Output: reward - deposited reward from the reward treasury
    // Output: excess_reward_calculated - flag to track if the excess reward is calculated by admin/treasury
    #[view]
    public fun get_app_config(
    ): (String, address, address, address, u64, u64, bool, u64, bool) acquires StakeApp {
        let staking_config = borrow_global<StakeApp>(@propbase);
        (staking_config.app_name, staking_config.admin, staking_config.treasury, staking_config.reward_treasurer, staking_config.min_stake_amount, staking_config.max_stake_amount, staking_config.emergency_locked, staking_config.reward, staking_config.excess_reward_calculated)
    }

    // This function is a view function that tracks StakePool state variable
    // Input: none
    // Output: pool_cap - maximum limit of the PROPS that can be staked in the pool from all users.
    // Output: staked_amount - total staked $PROPS amount by users
    // Output: epoch_start_time - pool start time in UNIX timestamp
    // Output: epoch_end_time - pool end time in UNIX timestamp
    // Output: interest_rate - APY % for staking 
    // Output: penalty_rate - fee percentage applied when a user unstakes.
    // Output: total_penalty - total penalty $PROPS transfered to treasury
    #[view]
    public fun get_stake_pool_config(
    ): (u64, u64, u64, u64, u64, u64, u64) acquires StakePool {
        let staking_pool_config = borrow_global<StakePool>(@propbase);
        (staking_pool_config.pool_cap, staking_pool_config.staked_amount, staking_pool_config.epoch_start_time, staking_pool_config.epoch_end_time, staking_pool_config.interest_rate, staking_pool_config.penalty_rate, staking_pool_config.total_penalty)
    }

    // This function is a view function that tracks reward expiry time
    // Output: reward expiry UNIX timestamp 
    #[view]
    public fun get_unclaimed_reward_withdraw_at(
    ): u64 acquires StakePool {
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        stake_pool_config.unclaimed_reward_withdraw_at
    }

    // This function is a view function that tracks users addresses staked in this contract 
    // Input: none
    // Output: vector of addresses
    #[view]
    public fun get_staked_addressess(): vector<address> acquires StakePool {
        let staking_pool_config = borrow_global<StakePool>(@propbase);
        staking_pool_config.staked_addressess
    }

    // This function is a view function that tracks users addresses who exited by withdrawing all principal amount 
    // Input: none
    // Output: vector of addresses
    #[view]
    public fun get_exited_addressess(): vector<address> acquires StakePool {
        let staking_pool_config = borrow_global<StakePool>(@propbase);
        staking_pool_config.exited_addressess
    }

    // This function is a view function that tracks UserInfo state variable
    // Input: user - user address
    // Output: principal - $PROPS amount staked by the user available in the pool at given time.
    // Output: withdrawn - $PROPS amount unstaked by the user at given time.
    // Output: accumulated_rewards - rewards are calculated and summed up whenever user stakes, unstakes and claim rewards.
    // Output: rewards_accumulated_at - timestamp at which accumulated_rewards are last calculated.
    // Output: first_staked_time - user first staked timestamp in UNIX
    // Output: last_staked_time - user last staked timestamp in UNIX
    // Output: is_total_earnings_withdrawn - Flag to track if the user has claimed all principal and reward after the pool ended.
    #[view]
    public fun get_user_info(
        user: address
    ): (u64, u64, u64, u64, u64, u64, bool) acquires UserInfo {
        if(!account::exists_at(user) || !exists<UserInfo>(user)) {
            return (0, 0, 0, 0, 0, 0, false)
        };
        let user_config = borrow_global<UserInfo>(user);
        return (
            user_config.principal,
            user_config.withdrawn,
            user_config.accumulated_rewards,
            user_config.rewards_accumulated_at,
            user_config.first_staked_time,
            user_config.last_staked_time,
            user_config.is_total_earnings_withdrawn,
        )
    }

    // This function is a view function that tracks users staked amounts
    // Input: user - user address
    // Output: vector of staked amounts
    #[view]
    public fun get_stake_amounts(
        user:address,
    ): vector<u64> acquires UserInfo {
        let amounts= vector::empty<u64>();
        if(!account::exists_at(user) || !exists<UserInfo>(user)) {
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

    // This function is a view function that tracks users staked timestamps
    // Input: user - user address
    // Output: vector of staked timestamps in UNIX
    #[view]
    public fun get_stake_time_stamps(
        user:address,
    ): vector<u64> acquires UserInfo {
        let timestamps= vector::empty<u64>();
        if(!account::exists_at(user) || !exists<UserInfo>(user)) {
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

    // This function is a view function that tracks users unstaked amounts
    // Input: user - user address
    // Output: vector of unstaked amounts
    #[view]
    public fun get_unstake_amounts(
        user:address,
    ): vector<u64> acquires UserInfo {
        let amounts= vector::empty<u64>();
        if(!account::exists_at(user) || !exists<UserInfo>(user)) {
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

    // This function is a view function that tracks users unstaked timestamps
    // Input: user - user address
    // Output: vector of unstaked timestamps in UNIX
    #[view]
    public fun get_unstake_time_stamps(
        user:address,
    ): vector<u64> acquires UserInfo {
        let timestamps= vector::empty<u64>();
        if(!account::exists_at(user) || !exists<UserInfo>(user)) {
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

    // This view function shows expected rewards if user kept the principal and the next stake amount till end of pool.
    // Input: principal - next stake amount willing to be deposited
    // Output: total reward $PROPS that can be earned for principal and next stake amount  
    #[view]
    public fun expected_rewards(
        user_address: address,
        principal: u64,
    ): u64 acquires StakePool, UserInfo, StakeApp {
        let accumulated_rewards = 0;
        let now = timestamp::now_seconds();
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        if(contract_config.emergency_locked){
            return 0
        };
        if(now > stake_pool_config.epoch_end_time) {
            return 0
        };
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

    // This view function shows $PROPS rewards that can be earned if given principal is staked till pool ends.
    // Input: principal - amount 
    // Output: total reward $PROPS that can be earned for given principal
    #[view]
    public fun expected_rewards_per_stake(
        principal: u64,
    ): u64 acquires StakePool, StakeApp {
        let accumulated_rewards = 0;
        let now = timestamp::now_seconds();
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        if(contract_config.emergency_locked){
            return 0
        };
        if(now > stake_pool_config.epoch_end_time) {
            return 0
        };
        if(principal > 0) {
            let reward = apply_reward_formula(
                principal,
                stake_pool_config.epoch_end_time - now,
                stake_pool_config.interest_rate,
                stake_pool_config.seconds_in_year
            );
            accumulated_rewards = (reward as u64);
        };
        accumulated_rewards
    }

    // This view function shows $PROPS rewards earned by a given user so far at a given time.
    // Input: user - User address
    // Output: total reward $PROPS currently earned
    #[view]
    public fun get_current_rewards_earned(
        user: address,
    ): u64 acquires UserInfo, StakePool, StakeApp {
        let rewards = 0;
        if(!account::exists_at(user) || !exists<UserInfo>(user)) {
            return rewards
        };
        let user_config = borrow_global<UserInfo>(user);
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global<StakePool>(@propbase);

        if(!user_config.is_total_earnings_withdrawn){
            rewards = get_total_rewards_so_far(
                user_config.principal,
                user_config.accumulated_rewards,
                user_config.rewards_accumulated_at,
                user_config.last_staked_time,
                stake_pool_config.interest_rate,
                stake_pool_config.seconds_in_year,
                stake_pool_config.epoch_end_time,
                contract_config.epoch_emergency_stop_time
            )
        };
        rewards
    }

    // This view function shows $PROPS rewards claimed by a given user
    // Input: user - User address
    // Output: total reward $PROPS claimed
    #[view]
    public fun get_rewards_claimed_by_user(
        user: address,
    ): u64 acquires ClaimPool {
        if(!account::exists_at(user) || !exists<UserInfo>(user)) {
            return 0
        }; 
        let claim_state = borrow_global<ClaimPool>(@propbase);
        if(!Table::contains(&claim_state.claimed_rewards, user)){
            return 0
        };
        return *Table::borrow(&claim_state.claimed_rewards, user)
    }

    // This view function tracks $PROPS reward balance in the contract at given time.
    // Input: none
    // Output: total reward $PROPS balance in the contract
    #[view]
    public fun get_contract_reward_balance(): u64 acquires RewardPool {
        let reward_state = borrow_global<RewardPool>(@propbase);
        reward_state.available_rewards
    }

    // This view function shows claimed rewards & principal of a given user
    // Input: none
    // Output: total claimed reward $PROPS by user
    // Output: total claimed principal $PROPS by user
    #[view]
    public fun get_total_claim_info(): (u64, u64) acquires ClaimPool {
        let claim_state = borrow_global<ClaimPool>(@propbase);
        return (claim_state.total_rewards_claimed, claim_state.total_claimed_principal)
    }

    // This view function shows $PROPS distributed addresses during emergency at given time.
    // Input: none
    // Output: vector of $PROPS distributed addresses
    #[view]
    public fun get_emergency_asset_distributed_addressess(): vector<address> acquires StakeApp {
        let staking_app_config = borrow_global<StakeApp>(@propbase);
        staking_app_config.emergency_asset_distributed_addressess
    }
}