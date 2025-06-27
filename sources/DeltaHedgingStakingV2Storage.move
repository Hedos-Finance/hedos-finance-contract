module hello_aptos_network::DeltaHedgingStakingV2Storage {
    use std::signer;

    use aptos_std::table;

    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self};
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    use amnis::amapt_token::AmnisApt;
    use amnis::stapt_token::StakedApt;
    use amnis::stapt_token;
    
    const PRECISION: u128 = 100000000;

    const AMAPT_ADDRESS:    address = @fungible_AMAPT;
    const APT_ADDRESS:      address = @fungible_APT;
    const LZ_USDT_ADDRESS:  address = @fungible_lzUSDT;
    const USDT_ADDRESS:     address = @fungible_USDT;
    const USDC_ADDRESS:     address = @fungible_USDC;

    struct StakeCaculator has key, store {
        userStakes: table::Table<address, u64>,
    }

    struct StakeAdmin has key, store {
        admin: address,
    }
    
    public entry fun init_stake_resources(
        account: &signer
    ) {
        let account_addr = signer::address_of(account);

        assert!(!exists<StakeAdmin>(account_addr), 0xE001); 
        assert!(!exists<StakeCaculator>(account_addr), 0xE002); 
    
        move_to(account, StakeAdmin {
            admin: account_addr,
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
    public fun get_total_stapt_view(): u64{
        coin::balance<StakedApt> (@hello_aptos_network)
    }

    #[view]
    public fun get_total_apt_view(): u64 {
        coin::balance<AptosCoin> (@hello_aptos_network)
    }
    
    #[view]
    public fun get_total_amapt_view(): u64 {
        coin::balance<AmnisApt> (@hello_aptos_network)
    }

    #[view]
    public fun get_admin_view(): address acquires StakeAdmin {
        let storage = borrow_global<StakeAdmin>(@hello_aptos_network);
        storage.admin
    }

    #[view]
    public fun get_total_lp_view(): u64 {
        let total_stapt = get_total_stapt_view();
        let total_apt = get_total_apt_view();
        let total_amapt = get_total_amapt_view();

        total_amapt = total_amapt + get_amapt_from_stapt_view(total_stapt);
        total_apt = total_apt + get_apt_from_amapt_view(total_amapt);
        let total_lp = get_usdc_from_apt_view(total_apt);
        total_lp
    }

    #[view]
    public fun get_usdc_from_apt_view(
        amount: u64
    ): u64 {
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        cellana::router::get_amounts_out(
            amount,
            apt,
            vector[USDC_ADDRESS],
            vector[false]
        )
    }

    #[view]
    public fun get_usdc_from_amapt_view(
        amount: u64
    ): u64 {
        let amapt = object::address_to_object<Metadata>(AMAPT_ADDRESS);
        cellana::router::get_amounts_out(
            amount,
            amapt,
            vector[APT_ADDRESS, USDC_ADDRESS],
            vector[true, false]
        )
    }

    #[view]
    public fun get_apt_from_amapt_view(
        amount: u64
    ): u64 {
        let amapt = object::address_to_object<Metadata>(AMAPT_ADDRESS);
        cellana::router::get_amounts_out(
            amount,
            amapt,
            vector[APT_ADDRESS],
            vector[true]
        )
    }

    #[view]
    public fun get_amapt_from_apt_view(
        amount: u64
    ): u64 {
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        cellana::router::get_amounts_out(
            amount,
            apt,
            vector[AMAPT_ADDRESS],
            vector[true]
        )
    }

    #[view]
    public fun get_amapt_from_stapt_view(
        amount: u64
    ): u64 {
        let ans = ((amount as u128) * (stapt_token::stapt_price() as u128) / PRECISION) as u64;
        ans
    }

    #[view]
    public fun get_stapt_from_amapt_view(
        amount: u64
    ): u64 {
        let ans = ((amount as u128) * PRECISION / (stapt_token::stapt_price() as u128)) as u64;
        ans
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
}


