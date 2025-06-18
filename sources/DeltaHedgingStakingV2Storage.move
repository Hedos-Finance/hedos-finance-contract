module hello_aptos_network::DeltaHedgingStakingV2Storage {

    use std::signer;
    
    use aptos_std::table;

    struct StakeCaculator has key, store {
        userStakes: table::Table<address, u64>,
    }

    struct StakeAdmin has key, store {
        admin: address,
        total_stapt: u64,
        total_apt: u64,
        total_usdc: u64
    }
    
    public entry fun init_stake_resources(
        account: &signer
    ) {
        let account_addr = signer::address_of(account);

        assert!(!exists<StakeAdmin>(account_addr), 0xE001); 
        assert!(!exists<StakeCaculator>(account_addr), 0xE002); 
    
        move_to(account, StakeAdmin {
            admin: account_addr,
            total_stapt: 0,
            total_apt: 0,
            total_usdc: 0
        });

    let userStakes = table::new<address, u64>();

    move_to(account, StakeCaculator { userStakes });
    }

    #[view]
    public fun get_user_stake_view(user: address): u64 acquires StakeCaculator {
    let storage = borrow_global<StakeCaculator>(@hello_aptos_network);
    if (table::contains(&storage.userStakes, user)) {
        *table::borrow(&storage.userStakes, user)
    } else {
        0
    }
    }

    #[view]
    public fun get_total_stake_view(): u64 acquires StakeAdmin {
        let storage = borrow_global<StakeAdmin>(@hello_aptos_network);
        storage.total_stapt
    }

    #[view]
    public fun get_total_apt_view(): u64 acquires StakeAdmin {
        let storage = borrow_global<StakeAdmin>(@hello_aptos_network);
        storage.total_apt
    }
    
    #[view]
    public fun get_admin_view(): address acquires StakeAdmin {
        let storage = borrow_global<StakeAdmin>(@hello_aptos_network);
        storage.admin
    }

    #[view]
    public fun get_total_usdc_view(): u64 acquires StakeAdmin {
        let storage = borrow_global<StakeAdmin>(@hello_aptos_network);
        storage.total_usdc
    }


    public entry fun set_user_stake(
        owner_signer: &signer,
        user: address,
        stake: u64,
        is_remove: bool
    ) acquires StakeCaculator, StakeAdmin {
        let owner = signer::address_of(owner_signer);
        assert!(owner == get_admin_view(), 1);
        let stake_caculator = borrow_global_mut<StakeCaculator>(owner);
        if (!is_remove) {
            if (table::contains(&stake_caculator.userStakes, user)) {
                table::remove(&mut stake_caculator.userStakes, user);
            };
            table::add(&mut stake_caculator.userStakes, user, stake);
        } else {
            if (table::contains(&stake_caculator.userStakes, user)) {
                table::remove(&mut stake_caculator.userStakes, user);
            };
        };
    }

    public entry fun set_total_stake(
        owner_signer: &signer,
        stake: u64
    ) acquires StakeAdmin {
        let owner = signer::address_of(owner_signer);
        assert!(owner == get_admin_view(), 1);
        let stake_admin = borrow_global_mut<StakeAdmin>(owner);
        stake_admin.total_stapt = stake;
    }

    public entry fun set_total_apt(
        owner_signer: &signer,
        apt: u64
    ) acquires StakeAdmin {
        let owner = signer::address_of(owner_signer);
        assert!(owner == get_admin_view(), 1);
        let stake_admin = borrow_global_mut<StakeAdmin>(owner);
        stake_admin.total_apt = apt;
    }

    public entry fun set_total_usdc(
        owner_signer: &signer,
        usdc: u64
    ) acquires StakeAdmin {
        let owner = signer::address_of(owner_signer);
        assert!(owner == get_admin_view(), 1);
        let stake_admin = borrow_global_mut<StakeAdmin>(owner);
        stake_admin.total_usdc = usdc;
    }
}


