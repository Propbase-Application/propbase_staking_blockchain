module propbase::propbase_staking {
    use std::string::{Self, String};
    use std::signer;
    use std::vector;
    use std::error;
    use std::debug;

    #[test_only]
    friend propbase::propbase_staking_tests;

    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::aptos_account;
    use aptos_std::table_with_length::{Self as Table, TableWithLength};
    use aptos_std::type_info;

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;
    
    struct StakeApp has key {
        app_name: String,
        signer_cap: account::SignerCapability,
        admin: address,
        treasury: address,
        reward_treasurers: TableWithLength<address, bool>,
        set_admin_events: EventHandle<SetAdminEvent>,
        set_treasury_events: EventHandle<SetTreasuryEvent>,
        set_reward_treasurers_events: EventHandle<vector<address>>,
        unset_reward_treasurers_events: EventHandle<vector<address>>,
    }

    struct StakePool has key {
        principal_amounts: TableWithLength<address, u64>,
        pool_cap: u64,
        epoch_start_time: u64,
        epoch_end_time: u64,
        interest_rate: u64,
        penalty_rate: u64,
        staked_amount: u64,
        set_pool_config_events: EventHandle<SetStakePoolEvent>,
    }

    struct RewardPool has key {
        available_rewards: u64,
        threshold: u64,
        updated_rewards_events: EventHandle<UpdateRewardsEvent>,
    }

    struct ClaimPool has key {
        total_claimed: u64,
        claimed_rewards: TableWithLength<address, u64>,
        claimable_rewards: TableWithLength<address, u64>,
        update_total_claimed_events: EventHandle<u64>,
    }

    struct UserInfo has key {
        principal: u64,
        withdrawn: u64,
        staked_items: vector<Stake>,
        unstaked_items: vector<Stake>,
        accumulated_rewards: u64,
        last_staked_time: u64,
    }

    struct Stake has drop, store {
        timestamp:u64,
        amount: u128,
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
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const ENOT_NOT_A_TREASURER: u64 = 2;
    const ESTAKE_POOL_ALREADY_CREATED: u64 = 3;
    const ESTAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME: u64 = 4;
    const ESTAKE_ALREADY_STARTED : u64 = 6;
    const ENOT_PROPS: u64 = 7;
    const EINVALID_AMOUNT: u64 = 8;
    const ENOT_IN_STAKING_RANGE: u64 = 9;
    const ENOT_STAKED_USER: u64 = 10;
    const EACCOUNT_DOES_NOT_EXIST: u64 = 11;
    const ESTAKE_POOL_INTEREST_OUT_OF_RANGE: u64 = 12;
    const ESTAKE_POOL_PENALTY_OUT_OF_RANGE: u64 = 13;
    const ESTAKE_POOL_CAP_OUT_OF_RANGE : u64 = 14;
    const ESTAKE_START_TIME_OUT_OF_RANGE : u64 = 15;
    const ESTAKE_END_TIME_OUT_OF_RANGE : u64 = 16;
    const ESTAKE_POOL_NAME_CANT_BE_EMPTY : u64 = 17;

    fun init_module(resource_account: &signer){
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
            set_admin_events: account::new_event_handle<SetAdminEvent>(resource_account),
            set_treasury_events: account::new_event_handle<SetTreasuryEvent>(resource_account),
            set_reward_treasurers_events: account::new_event_handle<vector<address>>(resource_account),
            unset_reward_treasurers_events: account::new_event_handle<vector<address>>(resource_account)

        });

        move_to(resource_account, StakePool {
            principal_amounts: Table::new(),
            pool_cap: 0,
            epoch_start_time: 0,
            epoch_end_time: 0,
            interest_rate: 0,
            penalty_rate: 0,
            staked_amount: 0,
            set_pool_config_events: account::new_event_handle<SetStakePoolEvent>(resource_account),

        });

        move_to(resource_account, RewardPool {
            available_rewards: 0,
            threshold: 0,
            updated_rewards_events: account::new_event_handle<UpdateRewardsEvent>(resource_account),

        });

        move_to(resource_account, ClaimPool {
            total_claimed: 0,
            claimed_rewards: Table::new(),
            claimable_rewards: Table::new(),
            update_total_claimed_events: account::new_event_handle<u64>(resource_account),
                    
        });
    }


    public entry fun set_admin(
        admin: &signer,
        new_admin_address: address,
    ) acquires StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let old_admin = contract_config.admin;

        assert!(account::exists_at(new_admin_address), error::invalid_argument(EACCOUNT_DOES_NOT_EXIST));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
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

        assert!(account::exists_at(new_treasury_address), error::invalid_argument(EACCOUNT_DOES_NOT_EXIST));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        
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

        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        
        let index = 0;
        let length = vector::length(&new_treasurers);
        
        while (index < length){
            let element = *vector::borrow(&new_treasurers, index);
            assert!(account::exists_at(element), error::invalid_argument(EACCOUNT_DOES_NOT_EXIST));
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
        
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
       
        let index = 0;
        let length = vector::length(&new_treasurers);
       
        while (index < length){
            let element = *vector::borrow(&new_treasurers, index);
            Table::upsert<address, bool>(&mut contract_config.reward_treasurers, element, false);
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
        value_config: vector<bool>
    ) acquires StakePool,StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);

        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        assert!(check_stake_pool_not_started(stake_pool_config.epoch_start_time) || stake_pool_config.epoch_start_time == 0, error::permission_denied(ESTAKE_ALREADY_STARTED));

        let set_pool_name = *vector::borrow(&value_config, 0);
        let set_pool_cap = *vector::borrow(&value_config, 1);
        let set_epoch_start_time = *vector::borrow(&value_config, 2);
        let set_epoch_end_time = *vector::borrow(&value_config, 3);
        let set_interest_rate = *vector::borrow(&value_config, 4);
        let set_penalty_rate = *vector::borrow(&value_config, 5);

        if(set_pool_cap){
            assert!(pool_cap > 0, error::invalid_argument(ESTAKE_POOL_CAP_OUT_OF_RANGE));
            stake_pool_config.pool_cap = pool_cap;          
        };
        if(set_epoch_start_time){
            assert!(epoch_start_time > 0, error::invalid_argument(ESTAKE_START_TIME_OUT_OF_RANGE));
            assert!(epoch_start_time < stake_pool_config.epoch_end_time || stake_pool_config.epoch_end_time == 0, error::invalid_argument(ESTAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
            stake_pool_config.epoch_start_time = epoch_start_time; 
        };
        if(set_epoch_end_time){
            assert!(epoch_end_time > 0, error::invalid_argument(ESTAKE_END_TIME_OUT_OF_RANGE));
            assert!(epoch_end_time > stake_pool_config.epoch_start_time, error::invalid_argument(ESTAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
            stake_pool_config.epoch_end_time = epoch_end_time;
        };
        if(set_penalty_rate){
            assert!(penalty_rate <= 50 && penalty_rate > 0, error::invalid_argument(ESTAKE_POOL_PENALTY_OUT_OF_RANGE));
            stake_pool_config.penalty_rate = penalty_rate;
        };
        if(set_interest_rate){
            assert!(interest_rate > 0 && interest_rate <= 100, error::invalid_argument(ESTAKE_POOL_INTEREST_OUT_OF_RANGE));
            stake_pool_config.interest_rate = interest_rate;
        };
        if (set_pool_name){
            assert!(pool_name != string::utf8(b""), error::invalid_argument(ESTAKE_POOL_NAME_CANT_BE_EMPTY));
            contract_config.app_name = pool_name;
        };
        event::emit_event<SetStakePoolEvent>(
            &mut stake_pool_config.set_pool_config_events,
            SetStakePoolEvent {
                pool_name : contract_config.app_name,
                pool_cap: stake_pool_config.pool_cap,
                epoch_start_time: stake_pool_config.epoch_start_time,
                epoch_end_time: stake_pool_config.epoch_end_time,
                interest_rate: stake_pool_config.interest_rate,
                penalty_rate: stake_pool_config.penalty_rate,
            }
        );

    }

    public entry fun stake_token<CoinType> (
        user: &signer,
        amount: u128

    )acquires  UserInfo, StakePool{

        let now = timestamp::now_seconds();
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);

        assert!(type_info::type_name<CoinType>() == string::utf8(b"0x1::propbase::PROP"), error::invalid_argument(ENOT_PROPS));
        assert!(amount >= 1000000000, error::invalid_argument(EINVALID_AMOUNT));
        assert!(now >= stake_pool_config.epoch_start_time && now < stake_pool_config.epoch_end_time, error::out_of_range(ENOT_IN_STAKING_RANGE));

        if(!exists<UserInfo>(signer::address_of(user))){
 
            let stake_buffer = vector::empty<Stake>();
            let unstake_buffer = vector::empty<Stake>();
            vector::push_back(&mut stake_buffer, Stake{timestamp: now, amount});

            move_to(user, UserInfo{
                principal: amount,
                withdrawn: 0,
                stake_events: stake_buffer,
                unstake_events: unstake_buffer,
                accumulated_rewards: 0,
                last_staked_time: now,

            });

            let prev_amount = stake_pool_config.stacked_amount;
            stake_pool_config.stacked_amount = prev_amount + (amount as u64);

            aptos_account::transfer_coins<CoinType>(user, @propbase, (amount as u64));

        }else {

            let user_state = borrow_global_mut<UserInfo>(signer::address_of(user));
            let accumulated_rewards = calculate_rewards(user_state.last_staked_time, now, stake_pool_config.interest_rate, user_state.principal );
            
            user_state.accumulated_rewards = accumulated_rewards;
            user_state.principal = user_state.principal + amount;
            user_state.last_staked_time = now;

            let prev_amount = stake_pool_config.stacked_amount;
            stake_pool_config.stacked_amount = prev_amount + (amount as u64);

            aptos_account::transfer_coins<CoinType>(user, @propbase, (amount as u64));

        }

    }

    #[test_only]
    public entry fun get_rewards (
        principal: u64,
        interest_rate: u64,
        from: u64,
        to: u64,
    ) {
        let rewards= calculate_rewards(from, to, intrest_rate, (principal as u128));
        debug::print<String>(&string::utf8(b"this is rewards result===================== #1"));
        debug::print(&rewards);

    }

    inline fun calculate_rewards(from:u64, to:u64, intrest_rate:u64, principal: u128):u128 {
        let time= calculate_time(from,to);
        debug::print<String>(&string::utf8(b"this is time result===================== #1"));
        debug::print(&time);
        let interest_per_second = (principal * (intrest_rate as u128));
        let interest_per_day = interest_per_second / 31622400;
        let remainder = interest_per_second % 31622400;
        let total_interest = (interest_per_day * (time as u128)) + ((remainder * (time as u128)) / 31622400);
        total_interest / 100
    }

    inline fun check_stake_pool_not_started(epoch_start_time: u64): bool{
        let now = timestamp::now_seconds();
        now < epoch_start_time
    }

    inline fun calculate_time(from:u64, to:u64):u64{
        let difference = to - from;
        if(difference < 86400){
            0
        }else{
            difference 
        }
        
    }

    //view functions
    #[test_only]
    #[view]
    public fun get_app_config(
    ): (String, address, address) acquires StakeApp {
        let staking_config = borrow_global<StakeApp>(@propbase);
        (staking_config.app_name, staking_config.admin, staking_config.treasury)
    }

    #[view]
    public fun get_stake_pool_config(
    ): (u64, u64, u64, u64, u64) acquires StakePool {
        let staking_pool_config = borrow_global<StakePool>(@propbase);
        (staking_pool_config.pool_cap, staking_pool_config.epoch_start_time, staking_pool_config.epoch_end_time, staking_pool_config.interest_rate, staking_pool_config.penalty_rate)
    }

    #[view]
    public fun check_is_reward_treasurers(
        user: address,
    ): bool acquires StakeApp{
        let staking_config = borrow_global<StakeApp>(@propbase);
        if(!Table::contains(&staking_config.reward_treasurers, user)){
            false
        }else{
            *Table::borrow(&staking_config.reward_treasurers, user)
        }
        

    }

    #[view]
    public fun get_stake_amounts(
        user:address,

    ): vector<u128> acquires UserInfo{
        assert!(exists<UserInfo>(user), error::invalid_argument(ENOT_STAKED_USER));
        let user_config = borrow_global<UserInfo>(user);
        let amounts= vector::empty<u128>();
        let i = 0;
        let len = vector::length(&user_config.stake_events);
        while (i < len){
            let element = vector::borrow(&user_config.stake_events, i);
            vector::push_back(&mut amounts, element.amount);
        };
        amounts

    }

    #[view]
    public fun get_stake_time_stamps(
        user:address,

    ): vector<u64> acquires UserInfo{
        assert!(exists<UserInfo>(user), error::invalid_argument(ENOT_STAKED_USER));
        let user_config = borrow_global<UserInfo>(user);
        let timestamps= vector::empty<u64>();
        let i = 0;
        let len = vector::length(&user_config.stake_events);
        while (i < len){
            let element = vector::borrow(&user_config.stake_events, i);
            vector::push_back(&mut timestamps, element.timestamp);
        };
        timestamps

    }
    #[view]
    public fun get_current_rewards_earned(
        user: &signer,

    ): u64 acquires UserInfo, StakePool {
        assert!(exists<UserInfo>(signer::address_of(user)), error::invalid_argument(ENOT_STAKED_USER));
        let user_config = borrow_global<UserInfo>(signer::address_of(user));
        let stake_pool_config = borrow_global<StakePool>(@propbase);
        let now = timestamp::now_seconds();

        if(user_config.accumulated_rewards != 0){
            let current_rewards= calculate_rewards(user_config.last_staked_time, now, stake_pool_config.interest_rate, user_config.principal);
            ((current_rewards as u64) + (user_config.accumulated_rewards as u64) )
        }else{
            let rewards = calculate_rewards(user_config.last_staked_time, now, stake_pool_config.interest_rate, user_config.principal); 
            (rewards as u64)   
        }

    }

}