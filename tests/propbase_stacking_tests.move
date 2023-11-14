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

}