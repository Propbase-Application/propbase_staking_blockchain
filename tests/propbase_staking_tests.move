#[test_only]
module propbase::propbase_staking_tests {

    use std::string::{Self, String};
    use std::signer;
    use std::vector;
    use std::error;

    use propbase::propbase_staking;
    use propbase::propbase_coin::{Self, PROPS};

    use aptos_framework::event::{Self, EventHandle};
    use aptos_std::math64::{max};
    use aptos_std::type_info;
    use std::debug;

    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::code;
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;

    use aptos_std::table::{Self, Table};

    fun setup_prop(resource:&signer,receivers:vector<address>) {
        propbase_coin::init_test(resource);
        let i = 0;
        let len = vector::length(&receivers);
        while (i < len){
            let element = *vector::borrow(&receivers, i);
            propbase_coin::mint(resource, element, 100000000000);
            i = i + 1;
        };
    }

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

        let (_, c_admin, _, _) = propbase_staking::get_app_config();
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
    #[expected_failure(abort_code = 0x1000B, location = propbase_staking )]
    fun test_failure_admin_change_not_valid_address(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);
        propbase_staking::set_admin(address_1, @0x0);
    
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
        let (_, _, c_treasury,_) = propbase_staking::get_app_config();

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
        propbase_staking::set_treasury(address_1, signer::address_of(address_1));

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x1000B, location = propbase_staking )]
    fun test_failure_treasury_change_not_valid_address(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        propbase_staking::set_treasury(admin, @0x0);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_add_reward_treasurers(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, signer::address_of(address_2));

        propbase_staking::add_reward_treasurers(admin, treasurers);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_1)), 2);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_2)), 3);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_add_reward_treasurers_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, signer::address_of(address_2));

        propbase_staking::add_reward_treasurers(address_1, treasurers);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x1000B, location = propbase_staking )]
    fun test_failure_add_reward_treasurers_not_valid_address(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, @0x0);

        propbase_staking::add_reward_treasurers(admin,treasurers);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_remove_reward_treasurers(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, signer::address_of(address_2));

        propbase_staking::add_reward_treasurers(admin, treasurers);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_1)), 2);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_2)), 3);

        propbase_staking::remove_reward_treasurers(admin, treasurers);
        assert!(!propbase_staking::check_is_reward_treasurers(signer::address_of(address_1)), 2);
        assert!(!propbase_staking::check_is_reward_treasurers(signer::address_of(address_2)), 3);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_remove_reward_treasurers_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        vector::push_back(&mut treasurers, signer::address_of(address_2));

        propbase_staking::add_reward_treasurers(admin, treasurers);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_1)), 2);
        assert!(propbase_staking::check_is_reward_treasurers(signer::address_of(address_2)), 3);

        propbase_staking::remove_reward_treasurers(address_1, treasurers);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_create_or_update_stake_pool(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);

        let (app_name, _, _,min_stake_amount) = propbase_staking::get_app_config();
        let (pool_cap, staked_amount, epoch_start_time, epoch_end_time, interest_rate, penalty_rate) = propbase_staking::get_stake_pool_config();

        assert!(app_name == string::utf8(b"Hello"), 4);
        assert!(pool_cap == 20000000000, 5);
        assert!(epoch_start_time == 80000, 6);
        assert!(epoch_end_time == 250000, 7);
        assert!(penalty_rate == 15, 8);
        assert!(interest_rate == 50, 9);
        assert!(staked_amount == 0, 10);
        assert!(min_stake_amount == 1000000000, 11);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x90013, location = propbase_staking )]
    fun test_failure_create_or_update_stake_pool_not_enough_reward_allocated(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = ((170000 / 100) * (20000000000 / 31622400) * 50 );
        let lesser_funds = required_funds - 10;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, lesser_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_create_or_update_stake_pool_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10004, location = propbase_staking )]
    fun test_failure_create_or_update_stake_pool_start_time_greater_than_end_time(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 80000, 50, 15, 1000000000, update_config);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_epoch_start_time(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 90000, 0, 0, 0, 0,update_config2);

        let (pool_cap, staked_amount, epoch_start_time, epoch_end_time, interest_rate, penalty_rate) = propbase_staking::get_stake_pool_config();

        assert!(epoch_start_time == 90000, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_update_epoch_start_time_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 90000, 0, 0, 0, 1000000000, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_update_epoch_start_time_pool_already_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);

        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 90000, 0, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10004, location = propbase_staking )]
    fun test_failure_update_epoch_start_end_time_should_be_greater_than_start(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 250000, 0, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1000F, location = propbase_staking )]
    fun test_failure_update_epoch_start_time_must_be_greater_than_zero(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_app_name(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello2"), 0, 0, 90000, 0, 0, 0, update_config2);

        let (name, admin, treasury, min_stake_amount) = propbase_staking::get_app_config();

        assert!(name == string::utf8(b"Hello2"), 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_update_app_name_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello2"), 0, 0, 90000, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_update_app_name_pool_already_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello2"), 0, 0, 90000, 0, 0, 0, update_config2);

        let (name, admin, treasury, min_stake_amount) = propbase_staking::get_app_config();

        assert!(name == string::utf8(b"Hello2"), 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10011, location = propbase_staking )]
    fun test_failure_update_app_name_empty_name(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b""), 0, 0, 90000, 0, 0, 0, update_config2);

    }


    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_epoch_end_time(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 90000, 0, 0, 0, update_config2);

        let (pool_cap, staked_amount, epoch_start_time, epoch_end_time, interest_rate, penalty_rate) = propbase_staking::get_stake_pool_config();

        assert!(epoch_end_time == 90000, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_update_epoch_end_time_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 0, 90000, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_update_epoch_end_time_pool_already_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 90000, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10004, location = propbase_staking )]
    fun test_faiure_update_epoch_end_time_end_time_should_be_greater_than_start(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 80000, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_pool_cap(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = ((170000 / 100) * (21000000000 / 31622400) * 50 );
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 21000000000, 0, 0, 0, 0, 0, update_config2);

        let (pool_cap, staked_amount, epoch_start_time, epoch_end_time, interest_rate, penalty_rate) = propbase_staking::get_stake_pool_config();

        assert!(pool_cap == 21000000000, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_update_pool_cap_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 500, 0, 0, 0, 0, 0, update_config2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_update_pool_cap_pool_already_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 500, 0, 0, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1000E, location = propbase_staking )]
    fun test_failure_update_pool_cap_must_be_greater_than_zero(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x90013, location = propbase_staking )]
    fun test_failure_update_pool_cap_rewards_exhausted(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 21000000000, 80000, 250000, 50, 15, 1000000000, update_config);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_interest_rate(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 55, 0, 0, update_config2);

        let (pool_cap, staked_amount, epoch_start_time, epoch_end_time, interest_rate, penalty_rate) = propbase_staking::get_stake_pool_config();
        assert!(interest_rate == 55, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_update_interest_rate_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 0, 0, 55, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_update_interest_rate_pool_already_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 55, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1000C, location = propbase_staking )]
    fun test_failure_update_interest_rate_must_be_greater_than_zero(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1000C, location = propbase_staking )]
    fun test_failure_update_interest_rate_must_be_less_than_or_equal_to_hundred(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 101, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_penalty_rate(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 25, 0, update_config2);

        let (pool_cap, staked_amount, epoch_start_time, epoch_end_time, interest_rate, penalty_rate) = propbase_staking::get_stake_pool_config();

        assert!(penalty_rate == 25, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_update_penalty_rate_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 0, 0, 0, 25, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_update_penalty_rate_pool_already_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 25, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1000D, location = propbase_staking )]
    fun test_failure_update_penalty_rate_must_be_greater_than_zero(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1000D, location = propbase_staking )]
    fun test_failure_update_penalty_rate_must_be_less_than_or_equal_to_fifty(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, false);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 51, 0, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_min_stake_amount(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 1000, update_config2);

        let (name, admin, treasury, min_stake_amount) = propbase_staking::get_app_config();

        assert!(min_stake_amount == 1000, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_update_min_stake_amount_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 1000, update_config2);


    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_update_min_stake_amount_pool_already_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 1000, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10014, location = propbase_staking )]
    fun test_failure_update_min_stake_amount_must_be_greater_than_zero(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        let update_config2 = vector::empty<bool>();
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, update_config2);

    }


    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successfull_get_rewards(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);

        let principal = propbase_staking::get_principal_amount(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (pool_cap, staked_amount, epoch_start_time, epoch_end_time, interest_rate, penalty_rate) = propbase_staking::get_stake_pool_config();
        
        assert!(principal == 10000000000, 1);
        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 10000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6)
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_add_stake_multiple_times(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let principal = propbase_staking::get_principal_amount(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _) = propbase_staking::get_stake_pool_config();

        assert!(principal == 10000000000, 1);
        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 2, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 2, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 5000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions, 1) == 5000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions, 1) == 90000, 8);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20009, location = propbase_staking )]
    fun test_failure_add_stake_pool_already_ended(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);
        fast_forward_secs(250000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20009, location = propbase_staking )]
    fun test_failure_add_stake_pool_not_started(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_add_stake_multiple_users(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);
        fast_forward_secs(10000);
        
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        propbase_staking::add_stake<PROPS>(address_1, 10000000000);

        let principal = propbase_staking::get_principal_amount(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _) = propbase_staking::get_stake_pool_config();

        assert!(principal == 10000000000, 1);
        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 10000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);

        let principal2 = propbase_staking::get_principal_amount(signer::address_of(address_2));
        let time_stamp_transactions2 = propbase_staking::get_stake_time_stamps(signer::address_of(address_2));
        let amount_transactions2 = propbase_staking::get_stake_amounts(signer::address_of(address_2));

        assert!(principal2 == 10000000000, 1);
        assert!(vector::length<u64>(&amount_transactions2) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions2) == 1, 4);
        assert!(*vector::borrow(&amount_transactions2, 0) == 10000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions2, 0) == 80000, 6);
        let (_, staked_amount2, _, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(staked_amount2 == 20000000000, 7);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successfull_add_reward_funds(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 5, 1000000000, update_config);
        let bal = propbase_staking::get_contract_reward_balance<PROPS>();
        assert!(bal == required_funds, 1)
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50002, location = propbase_staking )]
    fun test_failure_add_reward_funds_not_treasurer(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10012, location = propbase_staking )]
    fun test_failure_add_reward_funds_amount_must_be_greater_than_zero(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, 0);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_stake(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);


        let principal = propbase_staking::get_principal_amount(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _) = propbase_staking::get_stake_pool_config();

        propbase_staking::test_withdraw_stake<PROPS>(address_1, resource, 1000000000);
        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount_unstaked, _, _, _, _) = propbase_staking::get_stake_pool_config();

        let treasury_bal = coin::balance<PROPS>(@source_addr);

        assert!(principal == 1000000000, 1);
        assert!(staked_amount == 1000000000, 2);
        assert!(staked_amount_unstaked == 0, 2);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(vector::length<u64>(&amount_transactions_unstake) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 1000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions_unstake, 0) == 1000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions_unstake, 0) == 90000, 8);
        assert!(treasury_bal > 0, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5000A, location = propbase_staking )]
    fun test_failure_withdraw_stake_non_staked_user(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);


        let principal = propbase_staking::get_principal_amount(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _) = propbase_staking::get_stake_pool_config();

        propbase_staking::test_withdraw_stake<PROPS>(address_2, resource, 1000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10012, location = propbase_staking )]
    fun test_failure_withdraw_stake_amount_must_be_greater_than_zero(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);

        propbase_staking::test_withdraw_stake<PROPS>(address_1, resource, 0);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x90015, location = propbase_staking )]
    fun test_failure_withdraw_stake_not_enough_stake(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let treasurers = vector::empty<address>();
        vector::push_back(&mut treasurers, signer::address_of(address_1));
        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::add_reward_treasurers(admin, treasurers);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);

        propbase_staking::test_withdraw_stake<PROPS>(address_1, resource, 1400000000);

    }

    // #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    // fun test_successful_get_rewards(
    //     resource: &signer,
    //     admin: &signer,
    //     address_1: &signer,
    //     address_2: &signer,
    //     aptos_framework: &signer,
    // ) {
    //     setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 1000);
    //     propbase_staking::get_rewards(10000000000, 40, 1000, 87400);
    //     propbase_staking::get_rewards(10000000000, 40, 1000, 2593000);
    //     propbase_staking::get_rewards(10000000000, 40, 1000, 2679400);

    // }

}