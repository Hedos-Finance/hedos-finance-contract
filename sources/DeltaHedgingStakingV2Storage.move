module hello_aptos_network::DeltaHedgingStakingV2Storage {
    use std::signer;

    use aptos_std::table;
    use aptos_std::vector;

    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self};
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    use amnis::amapt_token::AmnisApt;
    use amnis::stapt_token::StakedApt;
    use amnis::stapt_token;

    use dex_contract::router_v3;
    use dex_contract::pool_v3;
    
    const PRECISION: u128 = 100000000;

    const AMAPT_ADDRESS:    address = @fungible_AMAPT;
    const APT_ADDRESS:      address = @fungible_APT;
    const LZ_USDT_ADDRESS:  address = @fungible_lzUSDT;
    const USDT_ADDRESS:     address = @fungible_USDT;
    const USDC_ADDRESS:     address = @fungible_USDC;

    const APT_USDT_LP_ADR: address = @fungible_APT_USDT_LP;
    const USDT_USDC_LP_ADR: address = @fungible_USDT_USDC_LP;
    const AMAPT_APT_LP_ADR: address = @fungible_AMAPT_APT_LP;

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;

    struct StakeCaculator has key, store {
        userStakes: table::Table<address, u64>,
    }

    struct StakeAdmin has key, store {
        admin: address,
    }
    
    struct SwapInformationInHyperion has key, store, drop {
        adr: vector<address>,
        coin_from: object::Object<Metadata>,
        coin_to: object::Object<Metadata>,
        slippage_type: u8,
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
    public fun get_coin_view<Coin0>(): u64 {
        coin::balance<Coin0> (@hello_aptos_network)
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

    #[view]
    public fun get_apt_usdc_price_hyperion(
        amount: u64, 
        slippage_type: u8
    ): u128 {
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let price = pool_v3::current_price(
            apt,
            usdc,
            slippage_type
        );

        let ans = (amount as u128) / price;
        ans
    }

    #[view]
    public fun get_apt_usdc_price_hyperion_2(
        amount: u64, 
        slippage_type: u8
    ): u64 {
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let price = router_v3::get_batch_amount_out(
            vector[APT_USDT_LP_ADR, USDT_USDC_LP_ADR],
            amount,
            apt,
            usdc
        );

        price
    }

    public entry fun set_swap_information_in_hyperion(
        owner_signer: &signer,
        coin_from: u8,
        coin_to: u8,
        slippage_type: u8
    ) acquires StakeAdmin, SwapInformationInHyperion {
        assert!(signer::address_of(owner_signer) == get_admin_view(), 1);
        let coins = vector::empty<address>();
        let x;
        let y;
        if (coin_from == USDC_CHOOSEN) {
            x = object::address_to_object<Metadata>(USDC_ADDRESS);
            y = object::address_to_object<Metadata>(APT_ADDRESS);

            coins.push_back(USDT_USDC_LP_ADR);
            coins.push_back(APT_USDT_LP_ADR);

            if (coin_to == AMAPT_CHOOSEN) {
                y = object::address_to_object<Metadata>(AMAPT_ADDRESS);

                coins.push_back(AMAPT_APT_LP_ADR);
            };
        } else if (coin_from == APT_CHOOSEN) {
            x = object::address_to_object<Metadata>(APT_ADDRESS);
            
            if(coin_to == USDC_CHOOSEN) {
                y = object::address_to_object<Metadata>(USDC_ADDRESS);
                coins.push_back(APT_USDT_LP_ADR);
                coins.push_back(USDT_USDC_LP_ADR);
            } else {
                y = object::address_to_object<Metadata>(AMAPT_ADDRESS);
                coins.push_back(AMAPT_APT_LP_ADR);
            };
        } else {
            x = object::address_to_object<Metadata>(AMAPT_ADDRESS);
            y = object::address_to_object<Metadata>(APT_ADDRESS);

            coins.push_back(AMAPT_APT_LP_ADR);

            if (coin_to == USDC_CHOOSEN) {
                y = object::address_to_object<Metadata>(USDC_ADDRESS);
                coins.push_back(APT_USDT_LP_ADR);
                coins.push_back(USDT_USDC_LP_ADR);
            };
        };
        let ans = SwapInformationInHyperion {
            adr: coins,
            coin_from: x,
            coin_to: y,
            slippage_type
        };
        let swap_info = borrow_global_mut<SwapInformationInHyperion>(signer::address_of(owner_signer));
        if(!exists<SwapInformationInHyperion>(signer::address_of(owner_signer))) {
            move_to(owner_signer, ans);
        } else {
            *swap_info = ans;
        };
    }

    #[view]
    public fun get_adr(): vector<address> acquires SwapInformationInHyperion {
        let swap_info = borrow_global<SwapInformationInHyperion>(@hello_aptos_network);
        swap_info.adr
    }

    #[view]
    public fun get_coin_from(): object::Object<Metadata> acquires SwapInformationInHyperion {
        let swap_info = borrow_global<SwapInformationInHyperion>(@hello_aptos_network);
        swap_info.coin_from
    }

    #[view]
    public fun get_coin_to(): object::Object<Metadata> acquires SwapInformationInHyperion {
        let swap_info = borrow_global<SwapInformationInHyperion>(@hello_aptos_network);
        swap_info.coin_to
    }

    //need to call set before call get
    #[view]
    public fun get_X_Y_price_hyperion(
        amount: u64
    ): u64 acquires SwapInformationInHyperion {
        let price = router_v3::get_batch_amount_out(
            get_adr(),
            amount,
            get_coin_from(),
            get_coin_to()
        );
        price
    }
}


