module propbase::propbase_staking {
    use std::string::{Self,String};
    use std::signer;
    use std::vector;
    use std::error;
    use std::debug;

    #[test_only]
    friend propbase::propbase_staking_tests;

    use aptos_framework::event::{Self, EventHandle};
    use aptos_std::math64::{max};
    use aptos_std::type_info;
    use aptos_std::table_with_length::{Self as Table, TableWithLength};

    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::code;
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;

    use aptos_std::table::{Self, Table};
    
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
        penality_rate: u64,
        interest_rate: u64,
        stacked_amount: u64,
        is_pool_started: bool,
        set_start_time_events: EventHandle<SetStartTimeEvent>,
        set_end_time_events: EventHandle<SetEndTimeEvent>,
        set_pool_cap_events: EventHandle<SetPoolCapEvent>,
        update_interest_rate_events: EventHandle<UpdateInterestRateEvent>,
        update_penality_rate_events: EventHandle<UpdatePenalityRateEvent>,

    }

    struct RewardPool has key {
        availabe_rewards: u64,
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
        stake_events: vector<Stake>,
        unstake_events: vector<Stake>,
        accumulated_rewards: u64,
        last_staked_time: u64,
    }

    struct Stake has drop, store {
        timestamp:u64,
        amount: u64,
    }

    struct SetAdminEvent has drop, store {
        old_admin: address,
        new_admin: address,
    }

    struct SetTreasuryEvent has drop, store {
        old_treasury: address,
        new_treasury: address,

    }

    struct SetStartTimeEvent has drop, store {
        old_start_time: u64,
        new_start_time: u64,

    }

    struct SetEndTimeEvent has drop, store {
        old_end_time: u64,
        new_end_time: u64,

    }

    struct SetPoolCapEvent has drop, store {
        old_pool_cap: u64,
        new_pool_cap: u64,
    }

    struct UpdateInterestRateEvent has drop, store {
        old_interest_rate: u64,
        new_interest_rate: u64,

    }

    struct UpdatePenalityRateEvent has drop, store {
        old_penality_rate: u64,
        new_penality_rate: u64,

    }

    struct ClaimEvent has drop, store {
        user: address,
        amount: u64,

    }

    struct UpdateRewardsEvent has drop, store {
        old_rewards: u64,
        new_rewards: u64,

    }

    const ENOT_AUTHORIZED: u64 = 1;
    const ENOT_NOT_A_TREASURER: u64 = 2;
    const ESTAKE_POOL_ALREADY_CREATED: u64 = 3;
    const ESTAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME: u64 = 4;
    const ESTAKE_NOT_INTIALIZED: u64 = 5;
    const ESTAKE_ALREADY_STARTED: u64 = 6;

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
            penality_rate: 0,
            interest_rate: 0,
            stacked_amount: 0,
            is_pool_started: false,
            set_start_time_events: account::new_event_handle<SetStartTimeEvent>(resource_account),
            set_end_time_events: account::new_event_handle<SetEndTimeEvent>(resource_account),
            set_pool_cap_events: account::new_event_handle<SetPoolCapEvent>(resource_account),
            update_interest_rate_events: account::new_event_handle<UpdateInterestRateEvent>(resource_account),
            update_penality_rate_events: account::new_event_handle<UpdatePenalityRateEvent>(resource_account),

        });

        move_to(resource_account, RewardPool {
            availabe_rewards: 0,
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
            let element = *vector::borrow(&new_treasurers,index);
            Table::upsert<address, bool>(&mut contract_config.reward_treasurers,element, true);
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

    public entry fun create_stake_pool(
        admin: &signer,
        pool_name: String,
        pool_cap: u64,
        epoch_start_time: u64,
        epoch_end_time: u64,
        penality_rate: u64,
        interest_rate: u64

    ) acquires StakePool,StakeApp {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);

        assert!(contract_config.app_name == string::utf8(b""), error::already_exists(ESTAKE_POOL_ALREADY_CREATED));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        assert!(epoch_start_time < epoch_end_time , error::invalid_argument(ESTAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));

        contract_config.app_name = pool_name;
        stake_pool_config.pool_cap = pool_cap;
        stake_pool_config.epoch_start_time = epoch_start_time;
        stake_pool_config.epoch_end_time = epoch_end_time;
        stake_pool_config.penality_rate = penality_rate;
        stake_pool_config.interest_rate = interest_rate;

    }

    public entry fun update_epoch_start_time(
        admin:&signer,
        new_start_time:u64,

    ) acquires StakePool,StakeApp  {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let old_start_time = stake_pool_config.epoch_start_time;

        assert!(contract_config.app_name != string::utf8(b""), error::invalid_state(ESTAKE_NOT_INTIALIZED));
        assert!(check_stake_pool_not_started(old_start_time), error::permission_denied(ESTAKE_ALREADY_STARTED));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        assert!(new_start_time < stake_pool_config.epoch_end_time , error::invalid_argument(ESTAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
        
        stake_pool_config.epoch_start_time = new_start_time;

        event::emit_event<SetStartTimeEvent>(
            &mut stake_pool_config.set_start_time_events,
            SetStartTimeEvent{
                old_start_time,
                new_start_time
            }

        );
    }

    public entry fun update_epoch_end_time(
        admin:&signer,
        new_end_time:u64,

    ) acquires StakePool,StakeApp  {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let old_end_time = stake_pool_config.epoch_end_time;

        assert!(contract_config.app_name != string::utf8(b""), error::invalid_state(ESTAKE_NOT_INTIALIZED));
        assert!(check_stake_pool_not_started(stake_pool_config.epoch_start_time), error::permission_denied(ESTAKE_ALREADY_STARTED));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        assert!(new_end_time > stake_pool_config.epoch_start_time, error::invalid_argument(ESTAKE_END_TIME_SHOULD_BE_GREATER_THAN_START_TIME));
        
        stake_pool_config.epoch_end_time = new_end_time;

        event::emit_event<SetEndTimeEvent>(
            &mut stake_pool_config.set_end_time_events,
            SetEndTimeEvent{
                old_end_time,
                new_end_time
            }

        );
    }

    public entry fun update_pool_cap(
        admin:&signer,
        new_pool_cap:u64,

    ) acquires StakePool,StakeApp  {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let old_pool_cap = stake_pool_config.pool_cap;

        assert!(contract_config.app_name != string::utf8(b""), error::invalid_state(ESTAKE_NOT_INTIALIZED));
        assert!(check_stake_pool_not_started(stake_pool_config.epoch_start_time), error::permission_denied(ESTAKE_ALREADY_STARTED));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        
        stake_pool_config.pool_cap = new_pool_cap;

        event::emit_event<SetPoolCapEvent>(
            &mut stake_pool_config.set_pool_cap_events,
            SetPoolCapEvent{
                old_pool_cap,
                new_pool_cap
            }

        );
    }

    public entry fun update_interest_rate(
        admin:&signer,
        new_interest_rate:u64,

    ) acquires StakePool,StakeApp  {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let old_interest_rate = stake_pool_config.interest_rate;

        assert!(contract_config.app_name != string::utf8(b""), error::invalid_state(ESTAKE_NOT_INTIALIZED));
        assert!(check_stake_pool_not_started(stake_pool_config.epoch_start_time), error::permission_denied(ESTAKE_ALREADY_STARTED));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        
        stake_pool_config.interest_rate = new_interest_rate;

        event::emit_event<UpdateInterestRateEvent>(
            &mut stake_pool_config.update_interest_rate_events,
            UpdateInterestRateEvent{
                old_interest_rate,
                new_interest_rate
            }

        );
    }

    public entry fun update_penality_rate(
        admin:&signer,
        new_penality_rate:u64,

    ) acquires StakePool,StakeApp  {
        let contract_config = borrow_global_mut<StakeApp>(@propbase);
        let stake_pool_config = borrow_global_mut<StakePool>(@propbase);
        let old_penality_rate = stake_pool_config.penality_rate;

        assert!(contract_config.app_name != string::utf8(b""), error::invalid_state(ESTAKE_NOT_INTIALIZED));
        assert!(check_stake_pool_not_started(stake_pool_config.epoch_start_time), error::permission_denied(ESTAKE_ALREADY_STARTED));
        assert!(signer::address_of(admin) == contract_config.admin, error::permission_denied(ENOT_AUTHORIZED));
        
        stake_pool_config.penality_rate = new_penality_rate;

        event::emit_event<UpdatePenalityRateEvent>(
            &mut stake_pool_config.update_penality_rate_events,
            UpdatePenalityRateEvent{
                old_penality_rate,
                new_penality_rate
            }

        );
    }

    public entry fun get_rewards (
        principal: u64,
        intrest_rate: u64,
        from: u64,
        to: u64,

    ) {
        let rewards= calculate_rewards(from, to, intrest_rate, principal);
        debug::print<String>(&string::utf8(b"this is rewards result===================== #1"));
        debug::print(&rewards);

    }
    inline fun calculate_rewards(from:u64, to:u64, intrest_rate:u64, principal: u64):u64 {
        let days= calculate_time_in_days(from,to);
        debug::print<String>(&string::utf8(b"this is days result===================== #1"));
        debug::print(&days);
        ((principal * intrest_rate) / 366 )  * (days) / 100
    }

    inline fun check_stake_pool_not_started(epoch_start_time:u64):bool{
        let now = timestamp::now_seconds();
        if(now < epoch_start_time){
            true
        }else{
            false
        }
    }

    inline fun calculate_time_in_days(from:u64, to:u64):u64{
        let difference = to - from;
        difference / 86400
    }

    //view functions
    #[test_only]
    #[view]
    public fun get_app_config(
    ): (String, address, address) acquires StakeApp {
        let staking_config = borrow_global<StakeApp>(@propbase);
        (staking_config.app_name, staking_config.admin, staking_config.treasury)
    }

    #[test_only]
    #[view]
    public fun get_stake_pool_config(
    ): (u64, u64, u64, u64, u64) acquires StakePool {
        let staking_pool_config = borrow_global<StakePool>(@propbase);
        (staking_pool_config.pool_cap, staking_pool_config.epoch_start_time, staking_pool_config.epoch_end_time, staking_pool_config.penality_rate, staking_pool_config.interest_rate)
    }

    #[view]
    public fun check_is_reward_treasurers(
        user:address,

    ): bool acquires StakeApp{
        let staking_config = borrow_global<StakeApp>(@propbase);
        *Table::borrow(&staking_config.reward_treasurers, user)

    }

}