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
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;

    struct StakeApp has key {
        app_name: String,
        signer_cap: account::SignerCapability,
        admin: address,
        treasury: address,
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
        updated_rewards: EventHandle<UpdateRewards>,
    }

    struct ClaimPool has key {
        total_claimed: u64,
        penality_rate: u64,
        penality_rate_per_day: RatePerDay,
        pool_cap: u64,
        interest_rate_apy: u64,
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

    struct UpdateRewards has drop, store {
        old_rewards: u64,
        new_rewards: u64
    }

}