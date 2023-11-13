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

    struct StakePool has key {
        signer_cap: account::SignerCapability,
        admin: address,
        treasury: address,
        pool_name: String,
        principal_amounts: TableWithLength<address, u64>,
        epoch_start_time: u64,
        epoch_end_time: u64,
        staked_size: u64,
        is_pool_started: bool,
        set_admin_events: EventHandle<SetAdminEvent>,
        set_treasury_events: EventHandle<SetTreasuryEvent>,
        set_start_time_events: EventHandle<SetStartTimeEvent>,
        set_end_time_events: EventHandle<SetEndTimeEvent>,
        set_pool_started_event: EventHandle<bool>
    }

    struct RewardPool has key {
        pool_cap: u64,
        intrest_rate_apy: u64,
        intrest_rate_per_day: RatePerDay,
        claimed_rewards: TableWithLength<address, u64>,
        claimable_rewards: TableWithLength<address, u64>,
        update_intrest_rate_events: EventHandle<UpdateIntrestRateEvent>,
    }

    struct ClaimPool has key {
        total_claimed: u64,
        penality_rate: u64,
        penality_rate_per_day: RatePerDay,
        claim_event: EventHandle<ClaimEvent>,
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

    struct UpdateIntrestRateEvent has drop, store {
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

}