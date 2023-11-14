#[test_only]
module propbase::propbase_stacking_tests {

    use std::string::{Self, String};
    use std::signer;
    use std::vector;
    use std::error;


    use propbase::propbase_staking;

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

    fun fast_forward_secs(
        seconds: u64
    ){
       timestamp::update_global_time_for_test_secs(timestamp::now_seconds() + seconds);
    }

    public(friend) fun setup_test(
       resource: &signer,
       admin: &signer,
       address_1: &signer,
       address_2: &signer,
    ){

        account::create_account_for_test(signer::address_of(resource));
        account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(address_1));
        account::create_account_for_test(signer::address_of(address_2));
        
        let seed = x"01";
        let (resource1, resource_signer_cap) = account::create_resource_account(admin, seed);
        let resource1_addr = signer::address_of(&resource1);
        propbase_staking::init_test(resource, resource_signer_cap);
    }

    public(friend) fun setup_test_time_based(
       resource: &signer,
       admin: &signer,
       address_1: &signer,
       address_2: &signer,
       framework: &signer,
       start_time: u64,
    ){

        timestamp::set_time_has_started_for_testing(framework);
        timestamp::update_global_time_for_test_secs(start_time);
        account::create_account_for_test(signer::address_of(resource));
        account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(address_1));
        account::create_account_for_test(signer::address_of(address_2));
        
        let seed = x"01";
        let (resource1, resource_signer_cap) = account::create_resource_account(admin, seed);
        let resource1_addr = signer::address_of(&resource1);
        propbase_staking::init_test(resource, resource_signer_cap);
    }


    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_admin_change(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);

        propbase_staking::set_admin(admin,signer::address_of(address_1));

        let (_, c_admin, _) = propbase_staking::get_app_config();
        assert!(c_admin == signer::address_of(address_1), 1)

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_admin_change_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,

    ) {
        
        setup_test(resource, admin, address_1, address_2);
        propbase_staking::set_admin(address_1, signer::address_of(address_1));
    
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_treasury_change(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);

        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        let (_, _, c_treasury) = propbase_staking::get_app_config();

        assert!(c_treasury == signer::address_of(address_1), 1)

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_treasury_change_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);
        propbase_staking::set_treasury(address_1,signer::address_of(address_1));

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_add_treasurers(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, signer::address_of(address_2));

        propbase_staking::add_reward_treasurers(admin,treasurers);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_1)), 2);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_2)), 3);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_add_treasurers_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, signer::address_of(address_2));

        propbase_staking::add_reward_treasurers(address_1,treasurers);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_remove_treasurers(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, signer::address_of(address_2));

        propbase_staking::add_reward_treasurers(admin,treasurers);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_1)), 2);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_2)), 3);

        propbase_staking::remove_reward_treasurers(admin,treasurers);
        assert!(!propbase_staking::check_is_reward_treasurers(signer::address_of(address_1)), 2);
        assert!(!propbase_staking::check_is_reward_treasurers(signer::address_of(address_2)), 3);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_remove_treasurers_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, signer::address_of(address_2));

        propbase_staking::add_reward_treasurers(admin,treasurers);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_1)), 2);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_2)), 3);

        propbase_staking::remove_reward_treasurers(address_1,treasurers);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_create_stake_pool(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);
        propbase_staking::create_stake_pool(admin,string::utf8(b"Hello"),5000000,80000,250000,15,50);

        let (app_name, _, _) = propbase_staking::get_app_config();
        let (pool_cap, epoch_start_time, epoch_end_time, penality_rate, interest_rate) = propbase_staking::get_stake_pool_config();

        assert!(app_name == string::utf8(b"Hello"), 4);
        assert!(pool_cap == 5000000, 5);
        assert!(epoch_start_time == 80000, 6);
        assert!(epoch_end_time == 250000, 7);
        assert!(penality_rate == 15, 8);
        assert!(interest_rate == 50, 9);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_create_stake_pool_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);
        propbase_staking::create_stake_pool(address_1,string::utf8(b"Hello"),5000000,80000,250000,15,50);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x80003, location = propbase_staking )]
    fun test_failure_create_stake_pool_already_created(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);
        propbase_staking::create_stake_pool(admin,string::utf8(b"Hello"),5000000,80000,250000,15,50);
        propbase_staking::create_stake_pool(admin,string::utf8(b"Hello"),5000000,80000,250000,15,50);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x10004, location = propbase_staking )]
    fun test_failure_create_stake_pool_start_time_greater_than_end_time(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        
        setup_test(resource, admin, address_1, address_2);
        propbase_staking::create_stake_pool(admin,string::utf8(b"Hello"),5000000,80000,80000,15,50);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_stake_start_time(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        propbase_staking::create_stake_pool(admin, string::utf8(b"Hello"), 5000000, 80000, 250000, 15, 50);
        propbase_staking::update_stake_start_time(admin,90000);

        let (pool_cap, epoch_start_time, epoch_end_time, penality_rate, interest_rate) = propbase_staking::get_stake_pool_config();

        assert!(epoch_start_time == 90000, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_update_stake_start_time(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        propbase_staking::create_stake_pool(admin, string::utf8(b"Hello"), 5000000, 80000, 250000, 15, 50);
        propbase_staking::update_stake_start_time(address_1,90000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x30005, location = propbase_staking )]
    fun test_failure_update_stake_start_time_stake_not_initialized(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        propbase_staking::update_stake_start_time(admin,90000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_update_stake_start_time_pool_already_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        propbase_staking::create_stake_pool(admin, string::utf8(b"Hello"), 5000000, 80000, 250000, 15, 50);
        fast_forward_secs(30000);
        propbase_staking::update_stake_start_time(admin,90000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10004, location = propbase_staking )]
    fun test_failure_update_stake_start_time_end_time_shuld_be_greater_than_start(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        propbase_staking::create_stake_pool(admin, string::utf8(b"Hello"), 5000000, 80000, 250000, 15, 50);
        propbase_staking::update_stake_start_time(admin,250000);

        let (pool_cap, epoch_start_time, epoch_end_time, penality_rate, interest_rate) = propbase_staking::get_stake_pool_config();

        assert!(epoch_start_time == 90000, 6);

    }


}