module propbase::propbase_staking {
    use std::string::{Self,String};
    use std::signer;
    use std::vector;

    use aptos_framework::event::{Self, EventHandle};
    use aptos_std::math64::{max};
    use aptos_std::type_info;
    use aptos_std::table_with_length::{Self as Table, TableWithLength};

    use aptos_framework::coin::{Self,Coin};
    use aptos_framework::code;
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;

    struct StakeApp has key {
        app_name: String,
        signer_cap: account::SignerCapability,
        admin: address,
        treasury: address,
        treasurers: TableWithLength<address, bool>,
        pool_cap: u64,
        set_admin_events: EventHandle<SetAdminEvent>,
        set_treasury_events: EventHandle<SetTreasuryEvent>,
    }

    struct StakePool has key {
        principal_amounts: TableWithLength<address, u64>,
        epoch_start_time: u64,
        epoch_end_time: u64,
        staked_amount: u64,
        is_pool_started: bool,
        set_start_time_events: EventHandle<SetStartTimeEvent>,
        set_end_time_events: EventHandle<SetEndTimeEvent>,
        set_pool_started_event: EventHandle<bool>
    }

    struct RewardPool has key {
        availabe_rewards: u64,
        threshold: u64,
        updated_rewards_events: EventHandle<UpdateRewardsEvent>,
    }

    struct ClaimPool has key {
        total_claimed: u64,
        penality_rate: u64,
        penality_rate_per_day: RatePerDay,
        interest_rate: u64,
        interest_rate_per_day: RatePerDay,
        claimed_rewards: TableWithLength<address, u64>,
        claimable_rewards: TableWithLength<address, u64>,
        update_interest_rate_events: EventHandle<UpdateInterestRateEvent>,
        update_penality_rate_events: EventHandle<UpdatePenalityRateEvent>,
        update_total_claimed_events: EventHandle<u64>,
    }

    struct RatePerDay has store {
        rate: u64,
        decimals: u16,
    }

    struct SetAdminEvent has drop, store {
        old_admin: address,
        new_admin: address
    }

    struct SetTreasuryEvent has drop, store {
        old_treasury: address,
        new_treasury: address
    }

    struct SetStartTimeEvent has drop, store {
        old_start_time: u64,
        new_start_time: u64
    }

    struct SetEndTimeEvent has drop, store {
        old_start_time: u64,
        new_start_time: u64
    }

    struct UpdateInterestRateEvent has drop, store {
        old_intrest_rate: u64,
        new_intrest_rate: u64
    }

    struct UpdatePenalityRateEvent has drop, store {
        old_penality_rate: u64,
        new_penality_rate: u64
    }

    struct ClaimEvent has drop, store {
        user: address,
        amount: u64
    }

    struct UpdateRewardsEvent has drop, store {
        old_rewards: u64,
        new_rewards: u64
    }

    fun init_module(resource_account: &signer){
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_account, @source_addr);        
        init_config(resource_account,resource_signer_cap);
    }

    fun init_config(resource_account: &signer, resource_signer_cap: SignerCapability) {
        
        move_to(resource_account, StakeApp {
            app_name: string::utf8(b"POOL_NAME"),
            signer_cap: resource_signer_cap,
            admin: @source_addr,
            treasury: @source_addr,
            treasurers: Table::new(),
            pool_cap: 0,
            set_admin_events: account::new_event_handle<SetAdminEvent>(resource_account),
            set_treasury_events: account::new_event_handle<SetTreasuryEvent>(resource_account),
            
        });

        move_to(resource_account, StakePool {
            principal_amounts: Table::new(),
            epoch_start_time: 0,
            epoch_end_time: 0,
            staked_amount: 0,
            is_pool_started: false,
            set_start_time_events: account::new_event_handle<SetStartTimeEvent>(resource_account),
            set_end_time_events: account::new_event_handle<SetEndTimeEvent>(resource_account),
            set_pool_started_event: account::new_event_handle<bool>(resource_account),

        });

        move_to(resource_account, RewardPool {
            availabe_rewards: 0,
            threshold: 0,
            updated_rewards_events: account::new_event_handle<UpdateRewardsEvent>(resource_account),

        });

        move_to(resource_account, ClaimPool {
            total_claimed: 0,
            penality_rate: 0,
            penality_rate_per_day: RatePerDay{ rate:0,decimals:0 },
            interest_rate: 0,
            interest_rate_per_day: RatePerDay{ rate:0,decimals:0 },
            claimed_rewards: Table::new(),
            claimable_rewards: Table::new(),
            update_interest_rate_events: account::new_event_handle<UpdateInterestRateEvent>(resource_account),
            update_penality_rate_events: account::new_event_handle<UpdatePenalityRateEvent>(resource_account),
            update_total_claimed_events: account::new_event_handle<u64>(resource_account),
                    
        })
    }

}