#[test_only]
module propbase::propbase_staking_tests {

    use std::string::{ Self, String, utf8 };
    use std::signer;
    use std::vector;
    use std::debug;

    use propbase::propbase_staking::{Self, UnStakeEvent};
    use propbase::propbase_coin::{ Self, PROPS };

    use aptos_framework::coin::{ Self };
    use aptos_framework::account::{ Self };
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::{ AptosCoin };
    use aptos_framework::event::{ Self };

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

        propbase_staking::init_test(resource);
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
        
        // let seed = x"01";
        // let (resource1, resource_signer_cap) = account::create_resource_account(admin, seed);
        // let resource1_addr = signer::address_of(&resource1);

        propbase_staking::init_test(resource);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_initial_state(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);
        let (app_name, c_admin, c_treasury, c_reward_treasurer, c_min_sale_amount, c_max_stake_amount, c_emergency_locked, c_reward, rewards_calculated) = propbase_staking::get_app_config();
        assert!(app_name == string::utf8(b""), 1);
        assert!(c_admin == signer::address_of(admin), 2);
        assert!(c_treasury == signer::address_of(admin), 3);
        assert!(c_reward_treasurer == signer::address_of(admin), 4);
        assert!(c_min_sale_amount == 0, 5);
        assert!(c_max_stake_amount == 0, 6);
        assert!(c_emergency_locked == false, 7);
        assert!(c_reward == 0, 8);
        assert!(rewards_calculated == false, 9);
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

        let (_, c_admin, _, _, _, _, _, _, _) = propbase_staking::get_app_config();
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

        let (_, _, i_treasury, _, _, _, _, _, _) = propbase_staking::get_app_config();
        assert!(i_treasury == signer::address_of(admin), 2);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        let (_, _, c_treasury, _, _, _, _, _, _) = propbase_staking::get_app_config();
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
    fun test_successful_set_reward_treasurer(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        let (_, _, _, treasurer_before, _, _, _, _, _) = propbase_staking::get_app_config();
        assert!(treasurer_before == signer::address_of(admin), 1);
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        let (_, _, _, treasurer, _, _, _, _, _) = propbase_staking::get_app_config();
        assert!(treasurer == signer::address_of(address_1), 2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_set_reward_treasurer_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        propbase_staking::set_reward_treasurer(address_1, signer::address_of(address_1));

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x1000B, location = propbase_staking )]
    fun test_failure_set_reward_treasurer_not_valid_address(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        propbase_staking::set_reward_treasurer(admin,@0x0);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    fun test_successful_remove_reward_treasurer(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);


        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        let (_, _, _, treasurer, _, _, _, _, _) = propbase_staking::get_app_config();
        assert!(treasurer == signer::address_of(address_1), 1);
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_2));
        let (_, _, _, treasurer, _, _, _, _, _) = propbase_staking::get_app_config();
        assert!(treasurer == signer::address_of(address_2), 2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_remove_reward_treasurer_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
    ) {
        setup_test(resource, admin, address_1, address_2);

        propbase_staking::set_reward_treasurer(address_1, signer::address_of(address_1));

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let interest = 20000000000 * 50;
        let interest_per_sec = interest / 31622400;
        let remainder = interest % 31622400;
        let total_interest = (interest_per_sec * (250000 - 80000)) + ((remainder * (250000 - 80000)) / 31622400);
        let required_funds = total_interest / 100;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);

        let (app_name, _, _, _, min_stake_amount, _, _, _, _) = propbase_staking::get_app_config();
        let (pool_cap, staked_amount, epoch_start_time, epoch_end_time, interest_rate, penalty_rate, total_penalty) = propbase_staking::get_stake_pool_config();

        assert!(app_name == string::utf8(b"Hello"), 4);
        assert!(total_penalty == 0, 5);
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = ((170000 / 100) * (20000000000 / 31622400) * 50 );
        let lesser_funds = required_funds - 10;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, lesser_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x90013, location = propbase_staking )]
    fun test_failure_create_or_update_stake_pool_pool_start_time_already_passed(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = ((170000 / 100) * (20000000000 / 31622400) * 50 );
        let lesser_funds = required_funds - 10;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, lesser_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);


        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10016, location = propbase_staking )]
    fun test_failure_create_or_update_stake_pool_invalid_seconds_in_year(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);


        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 300, update_config);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 80000, 50, 15, 1000000000, 10000000000, 31622400, update_config);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1001C, location = propbase_staking )]
    fun test_failure_create_or_update_stake_pool_start_already_passed(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        fast_forward_secs(20000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        let (_, _, epoch_start_time, _, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(epoch_start_time == 80000, 6);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 90000, 0, 0, 0, 0, 10, 31622400, update_config2);
        let (_, _, epoch_start_time, _, _, _, _) = propbase_staking::get_stake_pool_config();
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
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
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

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 90000, 0, 0, 0, 1000000000, 10000000000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 90000, 0, 0, 0, 0, 10, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 250000, 0, 0, 0, 0, 10, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, 10, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello2"), 0, 0, 90000, 0, 0, 0, 10, 31622400, update_config2);

        let (name, _, _, _, _, _, _, _, _) = propbase_staking::get_app_config();

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
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
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

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello2"), 0, 0, 90000, 0, 0, 0, 10, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello2"), 0, 0, 90000, 0, 0, 0, 10, 31622400, update_config2);

        let (name, _, _, _, _, _, _, _, _) = propbase_staking::get_app_config();

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);


        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b""), 0, 0, 90000, 0, 0, 0, 10000000000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        let (_, _, _, epoch_end_time, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(epoch_end_time == 250000, 6);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 90000, 0, 0, 0, 10000000000, 31622400, update_config2);
        let (_, _, _, epoch_end_time, _, _, _) = propbase_staking::get_stake_pool_config();
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000,  31622400, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 0, 90000, 0, 0, 0, 10000000000, 31622400, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10010, location = propbase_staking )]
    fun test_failure_update_epoch_end_time_must_be_greater_than_zero(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000,  31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, 10000000000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 90000, 0, 0, 0, 10, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 80000, 0, 0, 0, 10, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let interest = 21000000000 * 50;
        let interest_per_sec = interest / 31622400;
        let remainder = interest % 31622400;
        let total_interest = (interest_per_sec * (250000 - 80000)) + ((remainder * (250000 - 80000)) / 31622400);
        let required_funds = total_interest / 100;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        let (pool_cap, _, _, _, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(pool_cap == 20000000000, 6);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 21000000000, 0, 0, 0, 0, 0, 10, 31622400, update_config2);
        let (pool_cap, _, _, _, _, _, _) = propbase_staking::get_stake_pool_config();
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 500, 0, 0, 0, 0, 0, 10, 31622400, update_config2);
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 500, 0, 0, 0, 0, 0, 10, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, 10000000000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 21000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        let (_, _, _, _, interest_rate, _, _) = propbase_staking::get_stake_pool_config();
        assert!(interest_rate == 50, 6);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 55, 0, 0, 10000000000, 31622400, update_config2);
        let (_, _, _, _, interest_rate, _, _) = propbase_staking::get_stake_pool_config();
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 0, 0, 55, 0, 0, 1000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 55, 0, 0, 10000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, 10000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 101, 0, 0, 10000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        let (_, _, _, _, _, penalty_rate, _) = propbase_staking::get_stake_pool_config();
        assert!(penalty_rate == 15, 6);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 25, 0, 10000000000, 31622400, update_config2);
        let (_, _, _, _, _, penalty_rate, _) = propbase_staking::get_stake_pool_config();
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 0, 0, 0, 25, 0, 10000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 25, 0, 10000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, 1000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 51, 0, 10000000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 100000001, 1000, 31622400, update_config2);

        let (_, _, _, _, min_stake_amount, _, _, _, _) = propbase_staking::get_app_config();

        assert!(min_stake_amount == 100000001, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_min_stake_amount_equal_to_one(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 100000000, 1000, 31622400, update_config2);

        let (_, _, _, _, min_stake_amount, _, _, _, _) = propbase_staking::get_app_config();

        assert!(min_stake_amount == 100000000, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10014, location = propbase_staking )]
    fun test_failure_update_min_stake_amount_with_less_than_one(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 99999999, 1000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(address_1, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 1000, 10000000000, 31622400, update_config2);


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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(30000);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 10, 1000, 31622400, update_config2);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 0, 10, 31622400, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_update_max_stake_amount(
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
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
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

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 10, 1000000005, 31622400, update_config2);

        let (_, _, _, _, _, max_stake_amount, _, _, _) = propbase_staking::get_app_config();

        assert!(max_stake_amount == 1000000005, 6);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1001F, location = propbase_staking )]
    fun test_failure_update_max_stake_amount_max_must_be_greater_than_zero(
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
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, false);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 0, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 1000000002, 0, 31622400, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1001D, location = propbase_staking )]
    fun test_failure_update_max_stake_amount_max_must_be_less_than_pool_cap(
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
        vector::push_back(&mut update_config2, false);
        vector::push_back(&mut update_config2, true);
        vector::push_back(&mut update_config2, true);

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
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

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 0, 0, 0, 0, 0, 10, 20000000000, 31622400, update_config2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x1001F, location = propbase_staking )]
    fun test_failure_set_max_stake_amount_max_must_be_greater_than_min_amount(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin, string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 15, 1000000000, 1000000000, 31622400, update_config);
 
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let (p, _, _, _, _, _, _) = propbase_staking::get_user_info(@0x0);
        assert!(p == 0, 1);
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let amount_transactions_invalid = propbase_staking::get_stake_amounts(@0x0);
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let time_stamp_transactions_invalid = propbase_staking::get_stake_time_stamps(@0x0);
        assert!(vector::length<u64>(&time_stamp_transactions_invalid) == 0, 2);
        assert!(vector::length<u64>(&amount_transactions_invalid) == 0, 3);
        let (_, staked_amount, _, _, _, _, total_penalty) = propbase_staking::get_stake_pool_config();
        
        assert!(principal == 10000000000, 1);
        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 10000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(total_penalty == 0, 7)
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        assert!(vector::length<u64>(&amount_transactions) == 0, 3);
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        assert!(vector::length<u64>(&time_stamp_transactions) == 0, 4);
        let staked_addressess = propbase_staking::get_staked_addressess();
        assert!(vector::length<address>(&staked_addressess) == 0, 9);
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(staked_amount == 0, 2);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(staked_amount == 5000000000, 2);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time > 0, 14);
        assert!(first_staked_time == 80000, 15);
        assert!(!isWithdrawn , 16);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();

        assert!(principal == 10000000000, 111);
        assert!(withdrawn == 0, 112);
        assert!(accumulated_rewards > 0, 112);
        assert!(rewards_accumulated_at > 0, 113);
        assert!(last_staked_time > 0, 114);

        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 2, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 2, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 5000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions, 1) == 5000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions, 1) == 90000, 8);

        let staked_addressess = propbase_staking::get_staked_addressess();
        assert!(vector::length<address>(&staked_addressess) == 1, 9);
        assert!(*vector::borrow(&staked_addressess, 0) == signer::address_of(address_1), 10);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_add_stake_just_one_day_back(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        assert!(vector::length<u64>(&amount_transactions) == 0, 3);
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        assert!(vector::length<u64>(&time_stamp_transactions) == 0, 4);
        let staked_addressess = propbase_staking::get_staked_addressess();
        assert!(vector::length<address>(&staked_addressess) == 0, 9);
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(staked_amount == 0, 2);
        fast_forward_secs( 83600 - 1);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(staked_amount == 5000000000, 2);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time > 0, 14);
        assert!(first_staked_time == 163599, 15);
        assert!(!isWithdrawn , 16);


    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10007, location = propbase_staking )]
    fun test_failure_add_stake_non_props(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<AptosCoin>(address_1);
        coin::register<AptosCoin>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<AptosCoin>(address_1, 5000000000);

    }


    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10008, location = propbase_staking )]
    fun test_failure_add_stake_stake_must_be_greater_than_min(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 100000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x9001E, location = propbase_staking )]
    fun test_failure_add_stake_stake_must_be_less_than_max_existing_user(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<AptosCoin>(address_1);
        coin::register<AptosCoin>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 5000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x9001E, location = propbase_staking )]
    fun test_failure_add_stake_stake_must_be_less_than_max_new_user(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<AptosCoin>(address_1);
        coin::register<AptosCoin>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 5000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 9000000000);

    }


    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20025, location = propbase_staking )]
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(250000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20025, location = propbase_staking )]
    fun test_failure_add_stake_must_be_one_day_before(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(249999);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20025, location = propbase_staking )]
    fun test_failure_add_stake_after_pool_ended(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(250001);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x90005, location = propbase_staking )]
    fun test_failure_add_stake_pool_cap_exhausted(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        propbase_staking::add_stake<PROPS>(admin, 10000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20025, location = propbase_staking )]
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50023, location = propbase_staking )]
    fun test_failure_add_stake_pool_not_in_valid_state(
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
        vector::push_back(&mut update_config, false);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<AptosCoin>(address_1);
        coin::register<AptosCoin>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<AptosCoin>(address_1, 5000000000);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let interest = 20000000000 * 50;
        let interest_per_sec = interest / 31622400;
        let remainder = interest % 31622400;
        let total_interest = (interest_per_sec * (250000 - 80000)) + ((remainder * (250000 - 80000)) / 31622400);
        let required_funds = total_interest / 100;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 5, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);
        
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        propbase_staking::add_stake<PROPS>(address_1, 10000000000);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();

        assert!(principal == 10000000000, 1);
        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 10000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);

        let (principal2, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let time_stamp_transactions2 = propbase_staking::get_stake_time_stamps(signer::address_of(address_2));
        let amount_transactions2 = propbase_staking::get_stake_amounts(signer::address_of(address_2));

        assert!(principal2 == 10000000000, 1);
        assert!(vector::length<u64>(&amount_transactions2) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions2) == 1, 4);
        assert!(*vector::borrow(&amount_transactions2, 0) == 10000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions2, 0) == 80000, 6);
        let (_, staked_amount2, _, _, _, _, _) = propbase_staking::get_stake_pool_config();
        assert!(staked_amount2 == 20000000000, 7);

        let staked_addressess = propbase_staking::get_staked_addressess();
        assert!(vector::length<address>(&staked_addressess) == 2, 8);
        assert!(*vector::borrow(&staked_addressess, 0) == signer::address_of(address_1), 9);
        assert!(*vector::borrow(&staked_addressess, 1) == signer::address_of(address_2), 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x3001A, location = propbase_staking )]
    fun test_failure_add_stake_contract_emergency_stopped(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<AptosCoin>(address_1);
        coin::register<AptosCoin>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::emergency_stop(admin);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        let reward_balance = propbase_staking::get_contract_reward_balance();
        assert!(reward_balance == 0, 0);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 5, 1000000000, 10000000000, 31622400, update_config);
        let bal = propbase_staking::get_contract_reward_balance();
        assert!(bal == required_funds, 1)
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successfull_add_reward_funds_multiple_times(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        let reward_balance = propbase_staking::get_contract_reward_balance();
        assert!(reward_balance == 0, 0);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 5, 1000000000, 10000000000, 31622400, update_config);
        let bal = propbase_staking::get_contract_reward_balance();
        assert!(bal == required_funds, 1);
        fast_forward_secs(900);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        let bal2 = propbase_staking::get_contract_reward_balance();
        assert!(bal + required_funds == bal2, 2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successfull_add_reward_funds_one_second_before_start_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        let reward_balance = propbase_staking::get_contract_reward_balance();
        assert!(reward_balance == 0, 0);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 5, 1000000000, 10000000000, 31622400, update_config);
        let bal = propbase_staking::get_contract_reward_balance();
        assert!(bal == required_funds, 1);
        fast_forward_secs(999);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        let bal2 = propbase_staking::get_contract_reward_balance();
        assert!(bal + required_funds == bal2, 2);
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

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 65543, location = propbase_staking )]
    fun test_failure_add_reward_funds_not_props(
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

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::add_reward_funds<AptosCoin>(address_1, required_funds);
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, 0);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x3001A, location = propbase_staking )]
    fun test_failure_add_reward_funds_emergency_locked(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        let reward_balance = propbase_staking::get_contract_reward_balance();
        assert!(reward_balance == 0, 0);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 50, 5, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::emergency_stop(admin);
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_add_reward_funds_pool_already_started(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(15000);

        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50006, location = propbase_staking )]
    fun test_failure_add_reward_funds_at_pool_start(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();
        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_2));
        let rewards_observed = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        let events = event::emitted_events<UnStakeEvent>();
        let unstake_event = vector::borrow<UnStakeEvent>(&events, 0);
        let (withdrawn, amount, penality, accumulated_rewards, unstaked_time) = propbase_staking::extract_unstake_event(unstake_event);
        assert!(withdrawn == 1000000000, 1);
        assert!(amount == 1000000000, 2);
        assert!(penality == 500000000, 3);
        assert!(accumulated_rewards == 409836, 4);
        assert!(unstaked_time == 166400, 5);

        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount_unstaked, _, _, _, _, total_penalty2) = propbase_staking::get_stake_pool_config();
        let (principal2, withdrawn, _, rewards_accumulated_at, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_2));

        assert!(principal == 1000000000, 1);
        assert!(staked_amount == 1000000000, 2);
        assert!(staked_amount_unstaked == 0, 2);
        assert!(total_penalty1 == 0, 2);
        assert!(withdrawn == 1000000000, 3);
        assert!(principal2 == 0, 3);
        assert!(total_penalty2 == 500000000, 3);
        assert!(rewards_accumulated_at == 166400, 3);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(vector::length<u64>(&amount_transactions_unstake) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 1000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions_unstake, 0) == 1000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions_unstake, 0) == 166400, 8);
        assert!(treasury_bal_after == treasury_bal_before + 500000000 , 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_stake_at_one_day_after_first_stake(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();
        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_2));

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount_unstaked, _, _, _, _, total_penalty2) = propbase_staking::get_stake_pool_config();
        let (principal2, withdrawn, _, rewards_accumulated_at, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_2));

        assert!(principal == 1000000000, 1);
        assert!(staked_amount == 1000000000, 2);
        assert!(staked_amount_unstaked == 0, 2);
        assert!(total_penalty1 == 0, 2);
        assert!(withdrawn == 1000000000, 3);
        assert!(principal2 == 0, 3);
        assert!(total_penalty2 == 500000000, 3);
        assert!(rewards_accumulated_at == 166400, 3);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(vector::length<u64>(&amount_transactions_unstake) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 1000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions_unstake, 0) == 1000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions_unstake, 0) == 166400, 8);
        assert!(treasury_bal_after == treasury_bal_before + 500000000 , 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10007, location = propbase_staking )]
    fun test_failure_withdraw_stake_when_not_props(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        propbase_staking::withdraw_stake<AptosCoin>(address_1, 1000000000);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_stake_multiple_users(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        propbase_staking::add_stake<PROPS>(address_2, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 0, 4);
        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        assert!(vector::length<u64>(&amount_transactions_unstake) == 0, 3);

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        propbase_staking::withdraw_stake<PROPS>(address_2, 1000000000);
        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount_unstaked, _, _, _, _, total_penalty2) = propbase_staking::get_stake_pool_config();
        let (principal2, withdrawn, _, rewards_accumulated_at, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        let (_, withdrawn2, _, rewards_accumulated_at2, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let treasury_bal = coin::balance<PROPS>(@source_addr);

        assert!(principal == 1000000000, 1);
        assert!(staked_amount == 2000000000, 2);
        assert!(staked_amount_unstaked == 0, 2);
        assert!(total_penalty1 == 0, 2);
        assert!(withdrawn == 1000000000, 3);
        assert!(withdrawn2 == 1000000000, 3);
        assert!(principal2 == 0, 3);
        assert!(total_penalty2 == 1000000000, 3);
        assert!(rewards_accumulated_at == 166400, 3);
        assert!(rewards_accumulated_at2 == 166400, 3);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(vector::length<u64>(&amount_transactions_unstake) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 1000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions_unstake, 0) == 1000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions_unstake, 0) == 166400, 8);
        assert!(treasury_bal > 0, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_stake_check_balance_of_treasury(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(admin);
        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(admin));
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        // propbase_staking::set_reward_treasurer(admin, signer::address_of(admin));
        propbase_staking::add_reward_funds<PROPS>(admin, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        propbase_staking::add_stake<PROPS>(address_2, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 0, 4);
        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        assert!(vector::length<u64>(&amount_transactions_unstake) == 0, 3);

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(admin));

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        propbase_staking::withdraw_stake<PROPS>(address_2, 1000000000);
        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount_unstaked, _, _, _, _, total_penalty2) = propbase_staking::get_stake_pool_config();
        let (principal2, withdrawn, _, rewards_accumulated_at, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        let (_, withdrawn2, _, rewards_accumulated_at2, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let treasury_bal = coin::balance<PROPS>(@source_addr);
        let treasury_balance_after = coin::balance<PROPS>(signer::address_of(admin));

        assert!(principal == 1000000000, 1);
        assert!(staked_amount == 2000000000, 2);
        assert!(staked_amount_unstaked == 0, 2);
        assert!(total_penalty1 == 0, 2);
        assert!(withdrawn == 1000000000, 3);
        assert!(withdrawn2 == 1000000000, 3);
        assert!(principal2 == 0, 3);
        assert!(total_penalty2 == 1000000000, 3);
        assert!(rewards_accumulated_at == 166400, 3);
        assert!(rewards_accumulated_at2 == 166400, 3);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(vector::length<u64>(&amount_transactions_unstake) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 1000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions_unstake, 0) == 1000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions_unstake, 0) == 166400, 8);
        assert!(treasury_bal_before + total_penalty2 == treasury_balance_after, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x90015, location = propbase_staking )]
    fun test_failure_withdraw_stake_again_no_stake(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);
        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);

        propbase_staking::withdraw_stake<PROPS>(address_2, 1000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10014, location = propbase_staking )]
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);

        propbase_staking::withdraw_stake<PROPS>(address_1, 0);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10014, location = propbase_staking )]
    fun test_failure_withdraw_stake_amount_must_be_greater_than_one(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);

        propbase_staking::withdraw_stake<PROPS>(address_1, 10000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_stake_with_amount_equal_to_one(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();
        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_2));

        propbase_staking::withdraw_stake<PROPS>(address_1, 100000000);
        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount_unstaked, _, _, _, _, total_penalty2) = propbase_staking::get_stake_pool_config();
        let (principal2, withdrawn, _, rewards_accumulated_at, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_2));

        assert!(principal == 1000000000, 1);
        assert!(staked_amount == 1000000000, 2);
        assert!(staked_amount_unstaked == 900000000, 2);
        assert!(total_penalty1 == 0, 2);
        assert!(withdrawn == 100000000, 3);
        assert!(principal2 == 900000000, 3);
        assert!(total_penalty2 == 50000000, 3);
        assert!(rewards_accumulated_at == 166400, 3);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(vector::length<u64>(&amount_transactions_unstake) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 1000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions_unstake, 0) == 100000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions_unstake, 0) == 166400, 8);
        assert!(treasury_bal_after == treasury_bal_before + 50000000 , 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_stake_all_principal_and_check_exited_address(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();
        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_2));

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);

        let exited_addressess = propbase_staking::get_exited_addressess();
        assert!(vector::length<address>(&exited_addressess) == 1, 9);
        assert!(*vector::borrow(&exited_addressess, 0) == signer::address_of(address_1), 10);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_stake_and_check_staked_address(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        propbase_staking::add_stake<PROPS>(address_2, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();
        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_2));

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);

        let staked_addressess = propbase_staking::get_staked_addressess();
        assert!(vector::length<address>(&staked_addressess) == 1, 9);
        assert!(*vector::borrow(&staked_addressess, 0) == signer::address_of(address_2), 10);

        let exited_addressess = propbase_staking::get_exited_addressess();
        assert!(vector::length<address>(&exited_addressess) == 1, 9);
        assert!(*vector::borrow(&exited_addressess, 0) == signer::address_of(address_1), 10);
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        propbase_staking::withdraw_stake<PROPS>(address_1, 1400000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20009, location = propbase_staking )]
    fun test_failure_withdraw_stake_out_of_range(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(10000);
        fast_forward_secs(250000);


        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_success_withdraw_stake_at_pool_end_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(170000);


        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20009, location = propbase_staking )]
    fun test_success_withdraw_stake_after_one_second_of_pool_end_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(170001);


        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20024, location = propbase_staking )]
    fun test_failure_withdraw_stake_one_day_not_passed(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);


        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20024, location = propbase_staking )]
    fun test_failure_withdraw_stake_just_before_one_day_of_first_stake(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86399);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();
        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_2));

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x3001A, location = propbase_staking )]
    fun test_failure_withdraw_stake_contract_emergency_stopped(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();

        propbase_staking::emergency_stop(admin);
        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_add_stake_withdraw_stake_and_then_add_stake(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        let (principal, _, _, _, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, total_penalty1) = propbase_staking::get_stake_pool_config();

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        let amount_transactions_unstake = propbase_staking::get_unstake_amounts(signer::address_of(address_1));
        let time_stamp_transactions_unstake = propbase_staking::get_unstake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount_unstaked, _, _, _, _, total_penalty2) = propbase_staking::get_stake_pool_config();
        let (principal2, withdrawn, _, rewards_accumulated_at, _, _, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        let treasury_bal = coin::balance<PROPS>(@source_addr);

        assert!(principal == 1000000000, 1);
        assert!(staked_amount == 1000000000, 2);
        assert!(staked_amount_unstaked == 0, 2);
        assert!(total_penalty1 == 0, 2);
        assert!(withdrawn == 1000000000, 3);
        assert!(principal2 == 0, 3);
        assert!(total_penalty2 == 500000000, 3);
        assert!(rewards_accumulated_at == 166400, 3);
        assert!(vector::length<u64>(&amount_transactions) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 1, 4);
        assert!(vector::length<u64>(&amount_transactions_unstake) == 1, 3);
        assert!(vector::length<u64>(&time_stamp_transactions_unstake) == 1, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 1000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions_unstake, 0) == 1000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions_unstake, 0) == 166400, 8);
        assert!(treasury_bal > 0, 9);
        propbase_staking::claim_rewards<PROPS>(address_1);
        propbase_staking::add_stake<PROPS>(address_1, 2000000000);
        fast_forward_secs(10000);
        let rewards_observed = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed == 94869, 10);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_rewards_earned(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time > 8000, 14);



        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();

        assert!(principal == 10000000000, 111);
        assert!(withdrawn == 0, 112);
        assert!(accumulated_rewards > 0, 112);
        assert!(rewards_accumulated_at > 0, 113);
        assert!(last_staked_time == 90000, 114);

        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 2, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 2, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 5000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions, 1) == 5000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions, 1) == 90000, 8);
        let rewards_observed = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed == 237173, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_before_first_time_stake(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 5000000000);

        assert!(expected_rewards == 4269125, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_returns_zero_contract_emergency_stopped(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);

        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 5000000000);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(10000);
        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 0);
        propbase_staking::emergency_stop(admin);
        let expected_rewards2 = propbase_staking::expected_rewards(signer::address_of(address_1), 0);
        assert!(expected_rewards > 0, 8);
        assert!(expected_rewards2 == 0, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_returns_zero_when_contract_end_time_reached(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);

        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 5000000000);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(250000);
        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 0);

        assert!(expected_rewards == 0, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_rewards_earned_for_user_staking_second_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);


        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let rewards_observed_0 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed_0 == 0, 16);

         let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, is_total_earnings_withdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 0, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(first_staked_time == 0, 14);
        assert!(last_staked_time == 0, 14);
        assert!(is_total_earnings_withdrawn == false, 14);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed_1 == 237173, 15);


        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();

        assert!(principal == 10000000000, 111);
        assert!(withdrawn == 0, 112);
        assert!(accumulated_rewards == 474347, 112);
        assert!(rewards_accumulated_at == 100000, 113);

        assert!(last_staked_time == 100000, 114);

        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 2, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 2, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 5000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions, 1) == 5000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions, 1) == 100000, 8);
        let rewards_observed_2 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed_2 == 474347, 9);

        fast_forward_secs(10000);
        let rewards_observed_3 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed_3 == 711520+237174, 15);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_rewards_earned_after_epoch_ends(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);
        
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time > 8000, 14);

        fast_forward_secs(10000);
        
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 0);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let amount_transactions = propbase_staking::get_stake_amounts(signer::address_of(address_1));
        let time_stamp_transactions = propbase_staking::get_stake_time_stamps(signer::address_of(address_1));
        let (_, staked_amount, _, _, _, _, _) = propbase_staking::get_stake_pool_config();

        assert!(principal == 10000000000, 111);
        assert!(withdrawn == 0, 112);
        assert!(accumulated_rewards > 0, 112);
        assert!(rewards_accumulated_at > 0, 113);
        assert!(last_staked_time == 90000, 114);

        assert!(staked_amount == 10000000000, 2);
        assert!(vector::length<u64>(&amount_transactions) == 2, 3);
        assert!(vector::length<u64>(&time_stamp_transactions) == 2, 4);
        assert!(*vector::borrow(&amount_transactions, 0) == 5000000000, 5);
        assert!(*vector::borrow(&time_stamp_transactions, 0) == 80000, 6);
        assert!(*vector::borrow(&amount_transactions, 1) == 5000000000, 7);
        assert!(*vector::borrow(&time_stamp_transactions, 1) == 90000, 8);

        let rewards_observed = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed == 237173, 9);

        fast_forward_secs(250000);

        let rewards_observed = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed == expected_rewards, 10);

        fast_forward_secs(250000);
        let rewards_observed = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards_observed == 7826729, 11);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        let claimed_rewards2 = propbase_staking::get_rewards_claimed_by_user(@0x0);
        assert!(claimed_rewards == 0, 21);
        assert!(claimed_rewards2 == 0, 21);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        fast_forward_secs(86400);
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let calc_reward_invalid = propbase_staking::get_current_rewards_earned(@0x0);
        assert!(calc_reward_invalid == 0, 2);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards == 0, 21);

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        propbase_staking::claim_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming + calc_reward == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 * 2, 16);
        assert!(withdrawn == 0, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(rewards_accumulated_at == 176400, 18);
        assert!(last_staked_time == 90000, 19);

        let claimed_rewards1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards1 == 4335533, 20);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards1, 21);
        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards1, 22);
        assert!(total_claimed_principal == 0, 23);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards_with_less_period(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        let claimed_rewards2 = propbase_staking::get_rewards_claimed_by_user(@0x0);
        assert!(claimed_rewards == 0, 21);
        assert!(claimed_rewards2 == 0, 21);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        fast_forward_secs(86400);
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let calc_reward_invalid = propbase_staking::get_current_rewards_earned(@0x0);
        assert!(calc_reward_invalid == 0, 2);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards == 0, 21);

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        propbase_staking::claim_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming + calc_reward == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 * 2, 16);
        assert!(withdrawn == 0, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(rewards_accumulated_at == 176400, 18);
        assert!(last_staked_time == 90000, 19);

        let claimed_rewards1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards1 == 4335533, 20);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards1, 21);
        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards1, 22);
        assert!(total_claimed_principal == 0, 23);

        
        fast_forward_secs(1000);
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let now = timestamp::now_seconds();

        propbase_staking::claim_rewards<PROPS>(address_1);

        let claimed_rewards1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards1 == 4335533 + 47434, 20);
        
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming + calc_reward == bal_after_claiming, 15);
        assert!(calc_reward == 47434, 16);
        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 * 2, 16);
        assert!(withdrawn == 0, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(rewards_accumulated_at == 177400, 18);
        assert!(last_staked_time == 90000, 19);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards1, 21);
        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards1, 22);
        assert!(total_claimed_principal == 0, 23);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards_exactly_at_one_sec_before_pool_end_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        let claimed_rewards2 = propbase_staking::get_rewards_claimed_by_user(@0x0);
        assert!(claimed_rewards == 0, 21);
        assert!(claimed_rewards2 == 0, 21);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        fast_forward_secs(86400);
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let calc_reward_invalid = propbase_staking::get_current_rewards_earned(@0x0);
        assert!(calc_reward_invalid == 0, 2);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards == 0, 21);

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        propbase_staking::claim_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming + calc_reward == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 * 2, 16);
        assert!(withdrawn == 0, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(rewards_accumulated_at == 176400, 18);
        assert!(last_staked_time == 90000, 19);

        let claimed_rewards1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards1 == 4335533, 20);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards1, 21);
        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards1, 22);
        assert!(total_claimed_principal == 0, 23);

        
        fast_forward_secs(103599);
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let now = timestamp::now_seconds();

        propbase_staking::claim_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards_exactly_at_pool_end_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        let claimed_rewards2 = propbase_staking::get_rewards_claimed_by_user(@0x0);
        assert!(claimed_rewards == 0, 21);
        assert!(claimed_rewards2 == 0, 21);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        fast_forward_secs(86400);
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let calc_reward_invalid = propbase_staking::get_current_rewards_earned(@0x0);
        assert!(calc_reward_invalid == 0, 2);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards == 0, 21);

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        propbase_staking::claim_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming + calc_reward == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 * 2, 16);
        assert!(withdrawn == 0, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(rewards_accumulated_at == 176400, 18);
        assert!(last_staked_time == 90000, 19);

        let claimed_rewards1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards1 == 4335533, 20);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards1, 21);
        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards1, 22);
        assert!(total_claimed_principal == 0, 23);

        
        fast_forward_secs(103600);
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let now = timestamp::now_seconds();

        propbase_staking::claim_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20009, location = propbase_staking )]
    fun test_failure_claim_rewards_exactly_at_one_sec_after_pool_end_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        let claimed_rewards2 = propbase_staking::get_rewards_claimed_by_user(@0x0);
        assert!(claimed_rewards == 0, 21);
        assert!(claimed_rewards2 == 0, 21);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        fast_forward_secs(86400);

        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let calc_reward_invalid = propbase_staking::get_current_rewards_earned(@0x0);
        assert!(calc_reward_invalid == 0, 2);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards == 0, 21);

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        propbase_staking::claim_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming + calc_reward == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 * 2, 16);
        assert!(withdrawn == 0, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(rewards_accumulated_at == 176400, 18);
        assert!(last_staked_time == 90000, 19);

        let claimed_rewards1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_1));
        assert!(claimed_rewards1 == 4335533, 20);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards1, 21);
        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards1, 22);
        assert!(total_claimed_principal == 0, 23);

        
        fast_forward_secs(103601);
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        let now = timestamp::now_seconds();

        propbase_staking::claim_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards_multiple_times(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(86400);
        let rewards_earned1 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        propbase_staking::claim_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming + rewards_earned1 == bal_after_claiming, 11);

        fast_forward_secs(10000);
        let rewards_earned2 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let bal_before_claiming2 = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::claim_rewards<PROPS>(address_1);
        let bal_after_claiming2 = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming2 + rewards_earned2 == bal_after_claiming2, 11);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards_multiple_users(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        propbase_staking::add_stake<PROPS>(address_2, 4000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(86400);
        let rewards_earned1 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        propbase_staking::claim_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_before_claiming + rewards_earned1 == bal_after_claiming, 11);

         let rewards_earned1_user_2  = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_2));

        propbase_staking::claim_rewards<PROPS>(address_2);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_2));
        assert!(bal_before_claiming + rewards_earned1_user_2 == bal_after_claiming, 11);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10007, location = propbase_staking )]
    fun test_failure_claim_rewards_invalid_coin(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(86400);

        propbase_staking::claim_rewards<AptosCoin>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0xD0017, location = propbase_staking )]
    fun test_failure_claim_rewards_not_enough_accumulated(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(86400);

        propbase_staking::claim_rewards<PROPS>(address_1);
        propbase_staking::claim_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x3001A, location = propbase_staking )]
    fun test_failure_claim_rewards_contract_emergency_stopped(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);
        propbase_staking::emergency_stop(admin);
        propbase_staking::claim_rewards<PROPS>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5000A, location = propbase_staking )]
    fun test_failure_claim_rewards_non_stake_user(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        fast_forward_secs(86400);

        propbase_staking::claim_rewards<PROPS>(address_2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20019, location = propbase_staking )]
    fun test_failure_claim_rewards_when_claimed_within_24_hours_of_stake(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        propbase_staking::claim_rewards<PROPS>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20009, location = propbase_staking )]
    fun test_failure_claim_rewards_when_claimed_after_epoch_ends(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(250000);
        propbase_staking::claim_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x90013, location = propbase_staking )]
    fun test_failure_claim_rewards_when_rewards_are_not_added(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(20000);
        propbase_staking::claim_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards_and_principal(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000,  31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        fast_forward_secs(280000);    
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        assert!(bal_before_claiming + calc_reward + 5000000000 + 5000000000 == bal_after_claiming, 15);
        assert!(calc_reward == 9249771, 16);
        let (principal, withdrawn, accumulated_rewards, _, _, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 + 5000000000, 16);
        assert!(withdrawn == 5000000000 + 5000000000, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(last_staked_time == 90000, 19);
        assert!(isWithdrawn, 20);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10007, location = propbase_staking )]
    fun test_failure_claim_rewards_and_principal_invalid_coin(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        fast_forward_secs(280000);    
        
        propbase_staking::claim_principal_and_rewards<AptosCoin>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards_and_principal_after_emergency_is_declared(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(86400);
        propbase_staking::emergency_stop(admin);
            
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);

        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        assert!(bal_before_claiming + calc_reward + 5000000000 + 5000000000 == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, _, _, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 + 5000000000, 16);
        assert!(withdrawn == 5000000000 + 5000000000, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(last_staked_time == 90000, 19);
        assert!(isWithdrawn, 20);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5000A, location = propbase_staking )]
    fun test_failure_claim_rewards_and_principal_non_stake_user(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        fast_forward_secs(280000);    

        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20018, location = propbase_staking )]
    fun test_failure_claim_rewards_and_principal_out_of_range(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20018, location = propbase_staking )]
    fun test_failure_claim_rewards_and_principal_in_staking_range(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        fast_forward_secs(10000);    
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20018, location = propbase_staking )]
    fun test_failure_claim_rewards_and_principal_exactly_at_pool_ends(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   

        fast_forward_secs(200000);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_success_claim_rewards_and_principal_exactly_at_one_sec_after_pool_ends(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   

        fast_forward_secs(200001);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5001B, location = propbase_staking )]
    fun test_failure_claim_rewards_and_principal_already_withdrawn(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        fast_forward_secs(280000);    

        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_principal_and_reward_get_only_reward_when_all_principal_is_unstaked(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
   
        fast_forward_secs(86400);

        propbase_staking::withdraw_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(280000);    
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_after_claiming == bal_before_claiming + calc_reward , 10);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0xD0017, location = propbase_staking )]
    fun test_failure_claim_reward_when_all_principal_and_reward_are_withdrawn(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
   
        fast_forward_secs(86400);

        propbase_staking::withdraw_stake<PROPS>(address_1, 5000000000);
        propbase_staking::claim_rewards<PROPS>(address_1);

        fast_forward_secs(86400);    
        propbase_staking::claim_rewards<PROPS>(address_1);
    
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0xD0017, location = propbase_staking )]
    fun test_failure_claim_reward_when_n0_rewards(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
   
        fast_forward_secs(86400);

        propbase_staking::withdraw_stake<PROPS>(address_1, 5000000000);
        propbase_staking::claim_rewards<PROPS>(address_1); 
        propbase_staking::claim_rewards<PROPS>(address_1);
    
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5001B, location = propbase_staking )]
    fun test_failure_claim_rewards_and_principal_principal_and_rewards_already_taken(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
   
        fast_forward_secs(86400);

        propbase_staking::withdraw_stake<PROPS>(address_1, 5000000000);
        propbase_staking::claim_rewards<PROPS>(address_1);
        fast_forward_secs(280000);    
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_after_claiming == bal_before_claiming, 1);
        assert!(calc_reward == 0, 1);
    }
    

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_rewards_and_principal_five_years_passed_treasury_withdrawn_rewards_only_principal_is_recieved(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        fast_forward_secs(157960001);    
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::withdraw_unclaimed_rewards<PROPS>(address_2);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_after_claiming == bal_before_claiming + 10000000000, 13);
        
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_excess_rewards(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();

        propbase_staking::calculate_required_rewards(admin, 5);
        propbase_staking::withdraw_excess_rewards<PROPS>(address_1);

        let reward_balance_after_invoke = propbase_staking::get_contract_reward_balance();
        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        assert!(reward_balance_before_invoke - 9486946 == reward_balance_after_invoke, 1);
        assert!(bal_before_claiming + required_funds - 9486945  == bal_after_claiming, 2);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10007, location = propbase_staking )]
    fun test_failure_withdraw_excess_rewards_invalid_coin(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(86400);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(280000);   

        propbase_staking::withdraw_excess_rewards<AptosCoin>(admin);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50023, location = propbase_staking )]
    fun test_failure_withdraw_excess_rewards_contract_in_invalid_state(
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
        vector::push_back(&mut update_config, false);
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

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(86400);

        fast_forward_secs(280000);   

        propbase_staking::withdraw_excess_rewards<PROPS>(admin);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_withdraw_excess_rewards_not_treasury(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(86400);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(280000);   

        propbase_staking::withdraw_excess_rewards<PROPS>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20018, location = propbase_staking )]
    fun test_failure_withdraw_excess_rewards_pool_not_ended(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(86400);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::withdraw_excess_rewards<PROPS>(admin);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x3001A, location = propbase_staking )]
    fun test_failure_withdraw_excess_rewards_contract_emergency_locked(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(86400);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(280000);   
    
        propbase_staking::withdraw_excess_rewards<PROPS>(admin);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50020, location = propbase_staking )]
    fun test_failure_withdraw_excess_rewards_when_required_reward_not_calculated(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(86400);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(280000);   

        propbase_staking::calculate_required_rewards(admin, 1);
        propbase_staking::withdraw_excess_rewards<PROPS>(admin);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_unclaimed_rewards(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(86400);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(157960001);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000, 12);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        let contract_reward_bal = propbase_staking::get_contract_reward_balance();

        propbase_staking::withdraw_unclaimed_rewards<PROPS>(address_1);

        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        assert!(bal_before_claiming + contract_reward_bal == bal_after_claiming, 10);

        let contract_bal_after = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_after + contract_reward_bal == contract_bal_before, 12);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_unclaimed_rewards_user_sucessfully_withdraws_principal_only(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        let bal_before_staking = coin::balance<PROPS>(signer::address_of(address_2));

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(157960001);

        let bal_after_staking = coin::balance<PROPS>(signer::address_of(address_2));   
        
        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000, 12);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::withdraw_unclaimed_rewards<PROPS>(address_1);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);
        assert!(bal_before_staking == bal_after_staking + 10000000000, 13)

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10007, location = propbase_staking )]
    fun test_failure_withdraw_unclaimed_rewards_invalid_coin(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(157960001);

        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000, 12);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::withdraw_unclaimed_rewards<AptosCoin>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_withdraw_unclaimed_rewards_not_treasury(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(157960001);   
        
        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000, 12);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::withdraw_unclaimed_rewards<PROPS>(address_2);

    }
    
    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20019, location = propbase_staking )]
    fun test_failure_withdraw_unclaimed_rewards_five_year_not_passed(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        propbase_staking::set_reward_expiry_time(admin, 100055);


        fast_forward_secs(86400);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(280000);   
        
        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000, 12);

        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::withdraw_unclaimed_rewards<PROPS>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x3001A, location = propbase_staking )]
    fun test_failure_withdraw_unclaimed_rewards_contract_emergency_locked(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(157960001);

        propbase_staking::withdraw_unclaimed_rewards<PROPS>(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_set_reward_expiry_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (100000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        let deadline = propbase_staking::get_unclaimed_reward_withdraw_at();
        assert!(deadline == 0, 10);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 100000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        let deadline = propbase_staking::get_unclaimed_reward_withdraw_at();
        assert!(deadline == 63172000, 10);

        let previous_deadline = propbase_staking::get_unclaimed_reward_withdraw_at();
        assert!(previous_deadline == 63172000, 1);
        propbase_staking::set_reward_expiry_time(admin, 20000);
        let updated_deadline = propbase_staking::get_unclaimed_reward_withdraw_at();

        assert!(previous_deadline + 20000 == updated_deadline, 10);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_set_reward_expiry_time_not_admin(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (100000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 100000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::set_reward_expiry_time(address_1, 20000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50023, location = propbase_staking )]
    fun test_failure_set_reward_expiry_time_contract_not_in_valid_state(
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
        vector::push_back(&mut update_config, false);
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

        let difference = (100000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 100000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        propbase_staking::set_reward_expiry_time(address_1, 20000);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_on_stake_till_epoch_end(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 5000000000);
        assert!(expected_rewards == 4269125, 9);


        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);

        assert!(last_staked_time == 80000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards(signer::address_of(address_1), 0);
        assert!(rewards_observed_1 == 4031952, 15);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_on_double_stakes_till_epoch_end(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 5000000000);
        assert!(expected_rewards == 4269125, 9);

        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards(signer::address_of(address_1), 0);
        assert!(rewards_observed_1 == 4031952, 15);

        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 10000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 474347, 12);
        assert!(rewards_accumulated_at == 100000, 13);
        assert!(last_staked_time == 100000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards(signer::address_of(address_1), 0);
        assert!(rewards_observed_1 == 4031952 + 3557604, 15);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_on_double_stakes_and_new_principal_till_epoch_end(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 5000000000);
        assert!(expected_rewards == 4269125, 9);

        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards(signer::address_of(address_1), 0);
        assert!(rewards_observed_1 == 4031952, 15);

        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 10000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 474347, 12);
        assert!(rewards_accumulated_at == 100000, 13);
        assert!(last_staked_time == 100000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards(signer::address_of(address_1), 5000000000);
        assert!(rewards_observed_1 == 4031952 + 3557604 + 3320431, 15);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_to_be_zero_after_epoch_end_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        let expected_rewards = propbase_staking::expected_rewards(signer::address_of(address_1), 5000000000);
        assert!(expected_rewards == 4269125, 9);

        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);

        assert!(last_staked_time == 80000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards(signer::address_of(address_1), 0);
        assert!(rewards_observed_1 == 4031952, 15);

        fast_forward_secs(250000);
        let rewards_observed_1 = propbase_staking::expected_rewards(signer::address_of(address_1), 0);
        assert!(rewards_observed_1 == 0, 15);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_withdraw_excess_rewards_when_not_treasurer(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 1702270514);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (1792295300 - 1702270514);
        let req_funds : u128 = difference * (20000000000 * 50);
        let divisor = 31622400 * 100;
        let required_funds = req_funds / (divisor as u128);

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, (required_funds as u64));
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 1702270514, 1792295300, 50, 10, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(100);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(100);   


        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(100);   

        // propbase_staking::claim_rewards<PROPS>(address_1);
        fast_forward_secs(100);

        // propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(100);  
        fast_forward_secs(1792295300);

        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);

        propbase_staking::withdraw_excess_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_excess_rewards_after_user_claim_principal_and_rewards(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 1702270514);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (1792295300 - 1702270514);
        let req_funds : u128 = difference * 20000000000 * 50;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / (divisor as u128);

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, (required_funds as u64));
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 1702270514, 1792295300, 50, 10, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(100);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(100);   


        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(100);   

        // propbase_staking::claim_rewards<PROPS>(address_1);
        fast_forward_secs(100);

        // propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(100);  
        fast_forward_secs(1792295300);

        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);

        propbase_staking::calculate_required_rewards(admin, 5);
        propbase_staking::withdraw_excess_rewards<PROPS>(admin);
        
        let contract_bal_after = propbase_staking::get_contract_reward_balance();
        assert!(contract_bal_after == 0, 2)
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_withdraw_excess_rewards_before_user_claim_principal_and_rewards(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        aptos_framework: &signer,
    ) {

        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 1702270514);
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (1792295300 - 1702270514);
        let req_funds : u128 = difference * 20000000000 * 50;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / (divisor as u128);

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, (required_funds as u64));
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 1702270514, 1792295300, 50, 10, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(100);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(100);   


        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(100);   

        // propbase_staking::claim_rewards<PROPS>(address_1);
        fast_forward_secs(100);

        // propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(100);  
        fast_forward_secs(1792295300);
        propbase_staking::calculate_required_rewards(admin, 5);
        propbase_staking::withdraw_excess_rewards<PROPS>(admin);

        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);

        let contract_bal_after = propbase_staking::get_contract_reward_balance();
        assert!(contract_bal_after == 0, 2)
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_get_current_rewards_earned_works_after_user_withdraw_principal_and_rewards(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (250000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(170005);   

 
        let user_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        let rewards1 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);


        let rewards2 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));

    
        let user_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(rewards2 == 0, 2);
        assert!(rewards1 + user_bal_before + 10000000000 == user_bal_after, 3)

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful__withdraw_principal_and_rewards_with_exited_address(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (250000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(170005);   

 
        let user_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        let rewards1 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);

        let exited_addressess = propbase_staking::get_exited_addressess();
        assert!(vector::length<address>(&exited_addressess) == 1, 9);
        assert!(*vector::borrow(&exited_addressess, 0) == signer::address_of(address_1), 10);

    }

     #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful__withdraw_principal_and_rewards_with_staked_address(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (250000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(170005);   

 
        let user_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        let rewards1 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);

        let staked_addressess = propbase_staking::get_staked_addressess();
        assert!(vector::length<address>(&staked_addressess) == 0, 9);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_get_current_rewards_earned_returns_reward_accumlated_till_emergency_stop(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (250000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(admin));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(100005);   
        let rewards1 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(100005);
        let rewards2 = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        assert!(rewards2 == rewards1, 1)
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_principal_and_rewards(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(280000);
        
        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000, 1);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::calculate_required_rewards(admin, 5);
        propbase_staking::withdraw_excess_rewards<PROPS>(address_1);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        assert!(claimed_rewards == 0, 2);

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        let balance1 = coin::balance<PROPS>(signer::address_of(address_2));

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == 0, 15);
        assert!(total_claimed_principal == 0, 16);

        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        let balance = coin::balance<PROPS>(signer::address_of(address_2));

        assert!(balance == balance1 + 10000000000 + claimed_rewards, 3);
        assert!(claimed_rewards == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));
        
        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards, 13);
        assert!(total_claimed_principal == 10000000000, 13);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_claim_principal_and_rewards_in_case_of_emergency(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(5000);
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(280000);
        
        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000, 1);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));


        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        assert!(claimed_rewards == 0, 2);

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        let balance1 = coin::balance<PROPS>(signer::address_of(address_2));

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == 0, 15);
        assert!(total_claimed_principal == 0, 16);

        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        let balance = coin::balance<PROPS>(signer::address_of(address_2));

        assert!(balance == balance1 + 10000000000 + claimed_rewards, 3);
        assert!(claimed_rewards == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));
        
        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards, 13);
        assert!(total_claimed_principal == 10000000000, 13);
    }
    
    
    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    fun test_successful_claim_principal_and_rewards_for_multiple_users(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
 
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(280000);
        
        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000 + 8000000000, 1);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        propbase_staking::calculate_required_rewards(admin, 5);
        propbase_staking::withdraw_excess_rewards<PROPS>(address_1);

        // User 1
        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        assert!(claimed_rewards_1 == 0, 2);

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        let balance1 = coin::balance<PROPS>(signer::address_of(address_2));

        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);

        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        let balance = coin::balance<PROPS>(signer::address_of(address_2));

        assert!(balance == balance1 + 10000000000 + claimed_rewards_1, 3);
        assert!(claimed_rewards_1 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));
        
        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        // User 2
        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        assert!(claimed_rewards_2 == 0, 2);

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_3));

        let balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        propbase_staking::claim_principal_and_rewards<PROPS>(address_3);

        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        let balance = coin::balance<PROPS>(signer::address_of(address_3));

        assert!(balance == balance1 + 8000000000 + claimed_rewards_2, 3);
        assert!(claimed_rewards_2 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_3));
        
        assert!(principal == 8000000000, 5);
        assert!(withdrawn == 8000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == available_rewards_1 - claimed_rewards_2, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards_1 + claimed_rewards_2, 13);
        assert!(total_claimed_principal == 10000000000 + 8000000000, 13);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5001B, location = propbase_staking)]
    fun test_failure_claim_principal_and_rewards_rewards_already_distributed(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(5000);
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(280000);
        
        let contract_bal_before = coin::balance<PROPS>(@propbase);
        assert!(contract_bal_before == required_funds + 10000000000, 1);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));


        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        assert!(claimed_rewards == 0, 2);

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        let balance1 = coin::balance<PROPS>(signer::address_of(address_2));

        let available_rewards_1 = propbase_staking::get_contract_reward_balance();

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == 0, 15);
        assert!(total_claimed_principal == 0, 16);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 5);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5000A, location = propbase_staking)]
    fun test_failure_of_claim_principal_and_rewards_when_user_did_not_stake(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (100000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 100000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        fast_forward_secs(20000000000);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        assert!(claimed_rewards == 0, 21);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5001B, location = propbase_staking)]
    fun test_failure_of_claim_principal_and_rewards_when_user_already_claimed(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);

        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        fast_forward_secs(20000000000);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        assert!(claimed_rewards == 0, 21);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);
        fast_forward_secs(20000000000);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20018, location = propbase_staking)]
    fun test_failure_of_claim_principal_and_rewards_when_stake_is_in_progress(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);

        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        assert!(claimed_rewards == 0, 21);
        fast_forward_secs(200000);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10007, location = propbase_staking)]
    fun test_failure_of_claim_principal_and_rewards_when_coin_is_not_props(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);

        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        fast_forward_secs(280000);

        let claimed_rewards = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));
        assert!(claimed_rewards == 0, 21);
        fast_forward_secs(200000);
        propbase_staking::claim_principal_and_rewards<AptosCoin>(address_2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    fun test_successful_add_reward_funds(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        let (_, _, _, _, _, _, _, reward, _) = propbase_staking::get_app_config();
        assert!(reward == required_funds, 1);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        let (_, _, _, _, _, _, isStopped, _, _) = propbase_staking::get_app_config();
        assert!(isStopped ==false, 1);
        propbase_staking::emergency_stop(admin);
        let (_, _, _, _, _, _, isStopped2, _, _) = propbase_staking::get_app_config();
        assert!(isStopped2, 2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_get_unstake_time_stamps(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(admin);

        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (((250000 - 80000) / 100)* (20000000000/31622400)) * 50 ;
        propbase_staking::set_treasury(admin, signer::address_of(address_2));
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 1000000000);
        fast_forward_secs(86400);

        propbase_staking::withdraw_stake<PROPS>(address_1, 1000000000);

        let unstake_timestamps = propbase_staking::get_unstake_time_stamps(@0x0);
        let unstake_timestamps2 = propbase_staking::get_unstake_time_stamps(signer::address_of(address_2));
        let unstake_amounts = propbase_staking::get_unstake_amounts(@0x0);
        let unstake_amounts2 = propbase_staking::get_unstake_amounts(signer::address_of(address_2));
        let len = vector::length(&unstake_timestamps);
        let len2 = vector::length(&unstake_timestamps2);
        let len_amt = vector::length(&unstake_amounts);
        let len_amt2 = vector::length(&unstake_amounts2);
        assert!(len == 0, 1);
        assert!(len2 == 0, 2);
        assert!(len_amt == 0, 3);
        assert!(len_amt2 == 0, 4)

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_emergency_stop(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        let (_, _, _, _, _, _, isStopped, _, _) = propbase_staking::get_app_config();
        assert!(isStopped == false, 1);
        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        let (_, _, _, _, _, _, isStopped2, _, _) = propbase_staking::get_app_config();
        assert!(isStopped2 == true, 2);
        // assert!(treasury_bal_before + required_funds + 10000000000 == treasury_bal_after, 3);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_emergency_stop_works_if_contract_is_not_in_valid_state(
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
        vector::push_back(&mut update_config, false);
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

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        let (_, _, _, _, _, _, isStopped, _, _) = propbase_staking::get_app_config();
        assert!(isStopped == false, 1);
        propbase_staking::emergency_stop(admin);
        let (_, _, _, _, _, _, isStopped2, _, _) = propbase_staking::get_app_config();
        assert!(isStopped2 == true, 2);


    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_emergency_stop_not_admin(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        let (_, _, _, _, _, _, isStopped, _, _) = propbase_staking::get_app_config();
        assert!(isStopped ==false, 1);
        propbase_staking::emergency_stop(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20009, location = propbase_staking )]
    fun test_failure_emergency_stop_pool_ended(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        let (_, _, _, _, _, _, isStopped, _, _) = propbase_staking::get_app_config();
        assert!(isStopped ==false, 1);
        fast_forward_secs(280000);
        propbase_staking::emergency_stop(address_1);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10003, location = propbase_staking )]
    fun test_failure_emergency_stop_already_stopped(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(admin);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(resource);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        let (_, _, _, _, _, _, isStopped, _, _) = propbase_staking::get_app_config();
        assert!(isStopped ==false, 1);
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_stop(admin);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20009, location = propbase_staking )]
    fun test_failure_emergency_stop_pool_already_ended(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (170000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));
        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 170000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);
        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(170000);
        let (_, _, _, _, _, _, isStopped, _, _) = propbase_staking::get_app_config();
        assert!(isStopped ==false, 1);
        propbase_staking::emergency_stop(admin);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    fun test_successful_emergency_asset_distribution(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);

        
        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);
        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        let distributed_addressess = propbase_staking::get_emergency_asset_distributed_addressess();

        let expected_distributed_addressess = vector::empty<address>();
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_2));
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_3));

        assert!(distributed_addressess == expected_distributed_addressess, 15);



        // User 1
        let balance = coin::balance<PROPS>(signer::address_of(address_2));
        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        assert!(balance == user1_balance1 + 10000000000 + claimed_rewards_1, 3);
        // assert!(claimed_rewards_1 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));
        
        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        // User 2
        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        let balance = coin::balance<PROPS>(signer::address_of(address_3));

        assert!(balance == user2_balance1 + 8000000000 + claimed_rewards_2, 3);
        // assert!(claimed_rewards_2 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_3));
        
        assert!(principal == 8000000000, 5);
        assert!(withdrawn == 8000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == 0, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards_1 + claimed_rewards_2, 13);
        assert!(total_claimed_principal == 10000000000 + 8000000000, 14);
        
        assert!(treasury_bal_before + required_funds - total_rewards_claimed == treasury_bal_after, 16);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10007, location = propbase_staking )]
    fun test_failure_emergency_asset_distribution_when_not_props(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);

        
        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<AptosCoin>(admin, 0);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_emergency_asset_distribution_when_not_admin(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);
        
        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<PROPS>(address_1, 0);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x30022, location = propbase_staking)]
    fun test_failure_emergency_asset_distribution_when_not_in_emergency(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);
        
        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    fun test_successful_emergency_asset_distribution_with_user_limit_greater_than_zero(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);

        
        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 2);
        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        let distributed_addressess = propbase_staking::get_emergency_asset_distributed_addressess();

        let expected_distributed_addressess = vector::empty<address>();
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_2));
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_3));

        assert!(distributed_addressess == expected_distributed_addressess, 15);



        // User 1
        let balance = coin::balance<PROPS>(signer::address_of(address_2));
        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        assert!(balance == user1_balance1 + 10000000000 + claimed_rewards_1, 3);
        // assert!(claimed_rewards_1 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));
        
        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        // User 2
        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        let balance = coin::balance<PROPS>(signer::address_of(address_3));

        assert!(balance == user2_balance1 + 8000000000 + claimed_rewards_2, 3);
        // assert!(claimed_rewards_2 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_3));
        
        assert!(principal == 8000000000, 5);
        assert!(withdrawn == 8000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == 0, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards_1 + claimed_rewards_2, 13);
        assert!(total_claimed_principal == 10000000000 + 8000000000, 14);
        
        assert!(treasury_bal_before + required_funds - total_rewards_claimed == treasury_bal_after, 16);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    fun test_successful_emergency_asset_distribution_with_user_limit_greater_than_user_length(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);

        
        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 3);
        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        let distributed_addressess = propbase_staking::get_emergency_asset_distributed_addressess();

        let expected_distributed_addressess = vector::empty<address>();
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_2));
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_3));

        assert!(distributed_addressess == expected_distributed_addressess, 15);



        // User 1
        let balance = coin::balance<PROPS>(signer::address_of(address_2));
        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        assert!(balance == user1_balance1 + 10000000000 + claimed_rewards_1, 3);
        // assert!(claimed_rewards_1 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));
        
        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        // User 2
        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        let balance = coin::balance<PROPS>(signer::address_of(address_3));

        assert!(balance == user2_balance1 + 8000000000 + claimed_rewards_2, 3);
        // assert!(claimed_rewards_2 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_3));
        
        assert!(principal == 8000000000, 5);
        assert!(withdrawn == 8000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == 0, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards_1 + claimed_rewards_2, 13);
        assert!(total_claimed_principal == 10000000000 + 8000000000, 14);
        
        assert!(treasury_bal_before + required_funds - total_rewards_claimed == treasury_bal_after, 16);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    fun test_successful_emergency_asset_distribution_with_user_limit_less_than_user_length(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));
        
        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);

        
        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 1);
        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        let distributed_addressess = propbase_staking::get_emergency_asset_distributed_addressess();

        let expected_distributed_addressess = vector::empty<address>();
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_2));

        assert!(distributed_addressess == expected_distributed_addressess, 15);



        // User 1
        let balance = coin::balance<PROPS>(signer::address_of(address_2));
        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        assert!(balance == user1_balance1 + 10000000000 + claimed_rewards_1, 3);
        // assert!(claimed_rewards_1 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));
        
        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        // User 2
        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        let balance = coin::balance<PROPS>(signer::address_of(address_3));

        assert!(balance == user2_balance1, 3);
        // assert!(claimed_rewards_2 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_3));
        
        assert!(principal == 8000000000, 5);
        assert!(withdrawn == 0, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(!isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 > 0, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards_1, 13);
        assert!(total_claimed_principal == 10000000000, 14);
        
        assert!(treasury_bal_before == treasury_bal_after, 16);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    fun test_successful_emergency_asset_distribution_multiple_times(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);


        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 1);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 2);
        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        let distributed_addressess = propbase_staking::get_emergency_asset_distributed_addressess();

        let expected_distributed_addressess = vector::empty<address>();
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_2));
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_3));

        assert!(distributed_addressess == expected_distributed_addressess, 15);



        // User 1
        let balance = coin::balance<PROPS>(signer::address_of(address_2));
        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        assert!(balance == user1_balance1 + 10000000000 + claimed_rewards_1, 3);
        // assert!(claimed_rewards_1 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));

        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        // User 2
        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        let balance = coin::balance<PROPS>(signer::address_of(address_3));

        assert!(balance == user2_balance1 + 8000000000 + claimed_rewards_2, 3);
        // assert!(claimed_rewards_2 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_3));

        assert!(principal == 8000000000, 5);
        assert!(withdrawn == 8000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == 0, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards_1 + claimed_rewards_2, 13);
        assert!(total_claimed_principal == 10000000000 + 8000000000, 14);

        assert!(treasury_bal_before + required_funds - total_rewards_claimed == treasury_bal_after, 16);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    fun test_successful_emergency_asset_distribution_when_no_stakes(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);
        fast_forward_secs(40000);


        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);
        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        let distributed_addressess = propbase_staking::get_emergency_asset_distributed_addressess();

        let expected_distributed_addressess = vector::empty<address>();
        assert!(distributed_addressess == expected_distributed_addressess, 15);



        // User 1
        let balance = coin::balance<PROPS>(signer::address_of(address_2));
        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        assert!(balance == user1_balance1, 3);
        // assert!(claimed_rewards_1 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));

        assert!(principal == 0, 5);
        assert!(withdrawn == 0, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 0, 9);
        assert!(first_staked_time == 0, 10);
        assert!(!isPrincipalAndRewardWithdrawn , 11);

        // User 2
        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        let balance = coin::balance<PROPS>(signer::address_of(address_3));

        assert!(balance == user2_balance1, 3);
        // assert!(claimed_rewards_2 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_3));

        assert!(principal == 0, 5);
        assert!(withdrawn == 0, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 0, 9);
        assert!(first_staked_time == 0, 10);
        assert!(!isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == 0, 12);

        let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == 0, 13);
        assert!(total_claimed_principal == 0, 14);

        assert!(treasury_bal_before + required_funds == treasury_bal_after, 16);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, address_3 = @0xC, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5001B, location = propbase_staking)]
    fun test_failure_of_emergency_asset_distribution_when_called_after_complete_distribution(
        resource: &signer,
        admin: &signer,
        address_1: &signer,
        address_2: &signer,
        address_3: &signer,
        aptos_framework: &signer,
    ) {
        setup_test_time_based(resource, admin, address_1, address_2, aptos_framework, 70000);
        account::create_account_for_test(signer::address_of(address_3));

        let update_config = vector::empty<bool>();
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        coin::register<PROPS>(address_3);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        vector::push_back(&mut receivers, signer::address_of(address_3));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_3, 8000000000);
        fast_forward_secs(40000);


        let user1_balance1 = coin::balance<PROPS>(signer::address_of(address_2));
        let user2_balance1 = coin::balance<PROPS>(signer::address_of(address_3));

        let treasury_bal_before = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_stop(admin);
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);
        let treasury_bal_after = coin::balance<PROPS>(signer::address_of(address_1));
        let distributed_addressess = propbase_staking::get_emergency_asset_distributed_addressess();

        let expected_distributed_addressess = vector::empty<address>();
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_2));
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_3));
        assert!(distributed_addressess == expected_distributed_addressess, 15);



        // User 1
        let balance = coin::balance<PROPS>(signer::address_of(address_2));
        let claimed_rewards_1 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_2));

        let current_rewards_earned = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));

        assert!(balance == user1_balance1 + 10000000000 + claimed_rewards_1, 3);
        // assert!(claimed_rewards_1 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_2));

        assert!(principal == 10000000000, 5);
        assert!(withdrawn == 10000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        // User 2
        let claimed_rewards_2 = propbase_staking::get_rewards_claimed_by_user(signer::address_of(address_3));
        let balance = coin::balance<PROPS>(signer::address_of(address_3));

        assert!(balance == user2_balance1 + 8000000000 + claimed_rewards_2, 3);
        // assert!(claimed_rewards_2 == current_rewards_earned, 4);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isPrincipalAndRewardWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_3));

        assert!(principal == 8000000000, 5);
        assert!(withdrawn == 8000000000, 6);
        assert!(accumulated_rewards == 0, 7);
        assert!(rewards_accumulated_at == 0, 8);
        assert!(last_staked_time == 80000, 9);
        assert!(first_staked_time == 80000, 10);
        assert!(isPrincipalAndRewardWithdrawn , 11);

        let available_rewards_2 = propbase_staking::get_contract_reward_balance();
        assert!(available_rewards_2 == 0, 12);

       let (total_rewards_claimed, total_claimed_principal) = propbase_staking::get_total_claim_info();
        assert!(total_rewards_claimed == claimed_rewards_1 + claimed_rewards_2, 13);
        assert!(total_claimed_principal == 10000000000 + 8000000000, 14);

        assert!(treasury_bal_before + required_funds - total_rewards_claimed == treasury_bal_after, 16);

        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x5001B, location = propbase_staking)]
    fun test_failure_of_claim_rewards_and_principal_after_asset_is_distributed_by_admin(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(86400);
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(86400);
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);

        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        assert!(bal_before_claiming + calc_reward + 5000000000 + 5000000000 == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, _, _, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 + 5000000000, 16);
        assert!(withdrawn == 5000000000 + 5000000000, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(last_staked_time == 90000, 19);
        assert!(isWithdrawn, 20);

        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_emergency_asset_distribution_after_user_claimed_all_props(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(86400);
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(86400);
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);  

        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        assert!(bal_before_claiming + calc_reward + 5000000000 + 5000000000 == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, _, _, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 + 5000000000, 16);
        assert!(withdrawn == 5000000000 + 5000000000, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(last_staked_time == 90000, 19);
        assert!(isWithdrawn, 20);

        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);
        
        let bal_after_asset_distribution = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_after_claiming == bal_after_asset_distribution, 16);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_emergency_asset_distribution_multiple_users_after_one_user_claimed_all_props(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        propbase_staking::add_stake<PROPS>(address_2, 5000000000);
        fast_forward_secs(86400);
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(86400);
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let calc_reward_user_2 = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let bal_before_claiming_user_2 = coin::balance<PROPS>(signer::address_of(address_2));
        
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);  

        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        assert!(bal_before_claiming + calc_reward + 5000000000 + 5000000000 == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, _, _, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 + 5000000000, 16);
        assert!(withdrawn == 5000000000 + 5000000000, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(last_staked_time == 90000, 19);
        assert!(isWithdrawn, 20);

        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);
        
        let bal_after_asset_distribution = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_after_claiming == bal_after_asset_distribution, 16);

        let bal_after_claiming_user_2 = coin::balance<PROPS>(signer::address_of(address_2));

        assert!(bal_before_claiming_user_2 + calc_reward_user_2 + 5000000000 == bal_after_claiming_user_2, 15);
        assert!(calc_reward_user_2 == 2049180, 16);
        let (principal_user_2, withdrawn_user_2, accumulated_rewards_user_2, _, _, last_staked_time_user_2, isWithdrawn_user_2) = propbase_staking::get_user_info(signer::address_of(address_2));
        assert!(principal_user_2 == 5000000000, 16);
        assert!(withdrawn_user_2 == 5000000000, 17);
        assert!(accumulated_rewards_user_2 == 0, 17);
        assert!(last_staked_time_user_2 == 90000, 19);
        assert!(isWithdrawn_user_2, 20);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_emergency_asset_distribution_multiple_users_distributed_address(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, first_staked_time, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        
        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);
   
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        propbase_staking::add_stake<PROPS>(address_2, 5000000000);
        fast_forward_secs(86400);
        propbase_staking::emergency_stop(admin);
        fast_forward_secs(86400);
        let calc_reward = propbase_staking::get_current_rewards_earned(signer::address_of(address_1));
        let calc_reward_user_2 = propbase_staking::get_current_rewards_earned(signer::address_of(address_2));
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let bal_before_claiming_user_2 = coin::balance<PROPS>(signer::address_of(address_2));
        
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);  

        let bal_after_claiming = coin::balance<PROPS>(signer::address_of(address_1));

        assert!(bal_before_claiming + calc_reward + 5000000000 + 5000000000 == bal_after_claiming, 15);
        assert!(calc_reward == 4335533, 16);
        let (principal, withdrawn, accumulated_rewards, _, _, last_staked_time, isWithdrawn) = propbase_staking::get_user_info(signer::address_of(address_1));
        assert!(principal == 5000000000 + 5000000000, 16);
        assert!(withdrawn == 5000000000 + 5000000000, 17);
        assert!(accumulated_rewards == 0, 17);
        assert!(last_staked_time == 90000, 19);
        assert!(isWithdrawn, 20);

        propbase_staking::emergency_asset_distribution<PROPS>(admin, 0);
        
        let bal_after_asset_distribution = coin::balance<PROPS>(signer::address_of(address_1));
        assert!(bal_after_claiming == bal_after_asset_distribution, 16);

        let bal_after_claiming_user_2 = coin::balance<PROPS>(signer::address_of(address_2));

        assert!(bal_before_claiming_user_2 + calc_reward_user_2 + 5000000000 == bal_after_claiming_user_2, 15);
        assert!(calc_reward_user_2 == 2049180, 16);
        let (principal_user_2, withdrawn_user_2, accumulated_rewards_user_2, _, _, last_staked_time_user_2, isWithdrawn_user_2) = propbase_staking::get_user_info(signer::address_of(address_2));
        assert!(principal_user_2 == 5000000000, 16);
        assert!(withdrawn_user_2 == 5000000000, 17);
        assert!(accumulated_rewards_user_2 == 0, 17);
        assert!(last_staked_time_user_2 == 90000, 19);
        assert!(isWithdrawn_user_2, 20);

        let distributed_addressess = propbase_staking::get_emergency_asset_distributed_addressess();
        let expected_distributed_addressess = vector::empty<address>();
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_1));
        vector::push_back(&mut expected_distributed_addressess, signer::address_of(address_2));
        assert!(distributed_addressess == expected_distributed_addressess, 15);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_calculate_required_rewards(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();

        let (_, _, _, _, _, _, _, _, rewards_not_calculated) = propbase_staking::get_app_config();
        propbase_staking::calculate_required_rewards(admin, 5);
        let (_, _, _, _, _, _, _, _, rewards_calculated) = propbase_staking::get_app_config();
        assert!(!rewards_not_calculated, 1);
        assert!(rewards_calculated, 2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_calculate_required_rewards_for_user_already_withdrawn(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();

        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        propbase_staking::claim_principal_and_rewards<PROPS>(address_2);

        let (_, _, _, _, _, _, _, _, rewards_not_calculated) = propbase_staking::get_app_config();
        propbase_staking::calculate_required_rewards(admin, 5);
        let (_, _, _, _, _, _, _, _, rewards_calculated) = propbase_staking::get_app_config();
        assert!(!rewards_not_calculated, 1);
        assert!(rewards_calculated, 2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_calculate_required_rewards_with_input_zero(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();

        let (_, _, _, _, _, _, _, _, rewards_not_calculated) = propbase_staking::get_app_config();
        propbase_staking::calculate_required_rewards(address_1, 0);
        let (_, _, _, _, _, _, _, _, rewards_calculated) = propbase_staking::get_app_config();
        assert!(!rewards_not_calculated, 1);
        assert!(rewards_calculated, 2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_calculate_required_rewards_with_no_user_staked(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();

        let (_, _, _, _, _, _, _, _, rewards_not_calculated) = propbase_staking::get_app_config();
        propbase_staking::calculate_required_rewards(admin, 5);
        let (_, _, _, _, _, _, _, _, rewards_calculated) = propbase_staking::get_app_config();
        assert!(!rewards_not_calculated, 1);
        assert!(rewards_calculated, 2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_calculate_required_rewards_with_input_less_than_users(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();

        let (_, _, _, _, _, _, _, _, rewards_not_calculated1) = propbase_staking::get_app_config();
        propbase_staking::calculate_required_rewards(admin, 1);
        let (_, _, _, _, _, _, _, _, rewards_not_calculated2) = propbase_staking::get_app_config();
        assert!(!rewards_not_calculated1, 1);
        assert!(!rewards_not_calculated2, 2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_successful_calculate_required_rewards_with_input_more_than_users(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;
        
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        propbase_staking::add_stake<PROPS>(address_1, 10000000000);
        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();
        propbase_staking::claim_principal_and_rewards<PROPS>(address_1);
        let (_, _, _, _, _, _, _, _, rewards_not_calculated) = propbase_staking::get_app_config();
        propbase_staking::calculate_required_rewards(admin, 5);
        let (_, _, _, _, _, _, _, _, rewards_calculated) = propbase_staking::get_app_config();
        assert!(!rewards_not_calculated, 1);
        assert!(rewards_calculated, 2);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x50001, location = propbase_staking )]
    fun test_failure_calculate_required_rewards_not_admin_not_treasury(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();

        propbase_staking::calculate_required_rewards(address_2, 5);

    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x10021, location = propbase_staking )]
    fun test_failure_calculate_required_rewards_rewards_already_calculated(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);
        fast_forward_secs(280000);   
        
        let bal_before_claiming = coin::balance<PROPS>(signer::address_of(address_1));
        let reward_balance_before_invoke = propbase_staking::get_contract_reward_balance();

        propbase_staking::calculate_required_rewards(admin, 5);
        propbase_staking::calculate_required_rewards(admin, 5);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 0x20018, location = propbase_staking )]
    fun test_failure_calculate_required_rewards_pool_not_ended(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let difference = (280000 - 80000);
        let req_funds = difference * 20000000000 * 15;
        let divisor = 31622400 * 100;
        let required_funds = req_funds / divisor;

        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);
        propbase_staking::set_treasury(admin, signer::address_of(address_1));

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 280000, 15, 50, 1000000000, 10000000000, 31622400, update_config);
        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_2, 10000000000);

        propbase_staking::calculate_required_rewards(admin, 5);
        fast_forward_secs(280000);   
        

    }
    
    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_per_stake_before_first_time_stake(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        let expected_rewards = propbase_staking::expected_rewards_per_stake(5000000000);

        assert!(expected_rewards == 4269125, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_per_stake_returns_zero_contract_emergency_stopped(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        fast_forward_secs(10000);

        let expected_rewards = propbase_staking::expected_rewards_per_stake(4000000000);
        assert!(expected_rewards == 3225561, 8);
        propbase_staking::add_stake<PROPS>(address_1, 5000000000);
        fast_forward_secs(10000);
        let expected_rewards = propbase_staking::expected_rewards_per_stake(2000000000);
        propbase_staking::emergency_stop(admin);
        let expected_rewards2 = propbase_staking::expected_rewards_per_stake(5000000000);
        assert!(expected_rewards == 1517911, 8);
        assert!(expected_rewards2 == 0, 9);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_per_stake_on_double_stakes_and_new_principal_till_epoch_end(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        let expected_rewards = propbase_staking::expected_rewards_per_stake(5000000000);
        assert!(expected_rewards == 4269125, 9);

        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);
        assert!(last_staked_time == 80000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards_per_stake(5000000000);
        assert!(rewards_observed_1 == 3794778, 15);
        let rewards_observed_1 = propbase_staking::expected_rewards_per_stake(0);
        assert!(rewards_observed_1 == 0, 15);

        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 10000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 474347, 12);
        assert!(rewards_accumulated_at == 100000, 13);
        assert!(last_staked_time == 100000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards_per_stake(5000000000);
        assert!(rewards_observed_1 == 3320431, 15);
    }

    #[test(resource = @propbase, admin = @source_addr, address_1 = @0xA, address_2 = @0xB, aptos_framework = @0x1)]
    fun test_expected_rewards_per_stake_to_be_zero_after_epoch_end_time(
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
        vector::push_back(&mut update_config, true);
        vector::push_back(&mut update_config, true);

        coin::register<PROPS>(address_1);
        coin::register<PROPS>(address_2);
        let receivers = vector::empty<address>();
        vector::push_back(&mut receivers, signer::address_of(address_1));
        vector::push_back(&mut receivers, signer::address_of(address_2));
        setup_prop(resource, receivers);

        let required_funds = (20000000000 / 100) * 50;
        propbase_staking::set_reward_treasurer(admin, signer::address_of(address_1));
        propbase_staking::add_reward_funds<PROPS>(address_1, required_funds);

        propbase_staking::create_or_update_stake_pool(admin,string::utf8(b"Hello"), 20000000000, 80000, 250000, 15, 50, 1000000000, 10000000000, 31622400, update_config);

        let expected_rewards = propbase_staking::expected_rewards_per_stake(5000000000);
        assert!(expected_rewards == 4269125, 9);

        fast_forward_secs(10000);

        propbase_staking::add_stake<PROPS>(address_1, 5000000000);

        let (principal, withdrawn, accumulated_rewards, rewards_accumulated_at, _, last_staked_time, _) = propbase_staking::get_user_info(signer::address_of(address_1));

        assert!(principal == 5000000000, 1);
        assert!(withdrawn == 0, 11);
        assert!(accumulated_rewards == 0, 12);
        assert!(rewards_accumulated_at == 0, 13);

        assert!(last_staked_time == 80000, 14);

        fast_forward_secs(10000);
        let rewards_observed_1 = propbase_staking::expected_rewards_per_stake(5000000000);
        assert!(rewards_observed_1 == 3794778, 15);

        fast_forward_secs(250000);
        let rewards_observed_1 = propbase_staking::expected_rewards_per_stake(5000000000);
        assert!(rewards_observed_1 == 0, 15);
    }


}
