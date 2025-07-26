module delta_hedging::storage {
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
    
        move_to(account, StakeAdmin {
            admin: account_addr,
        });

        let userStakes = table::new<address, u64>();

        move_to(account, StakeCaculator { userStakes });
    }

    #[view]
    public fun get_user_stake_view(user: address): u64 acquires StakeCaculator {
    let storage = borrow_global<StakeCaculator>(@delta_hedging);
    if (table::contains(&storage.userStakes, user)) {
        *table::borrow(&storage.userStakes, user)
    } else {
        0
    }
    }

    #[view]
    public fun get_total_stapt_view(): u64{
        coin::balance<StakedApt> (@delta_hedging)
    }

    #[view]
    public fun get_total_apt_view(): u64 {
        coin::balance<AptosCoin> (@delta_hedging)
    }
    
    #[view]
    public fun get_total_amapt_view(): u64 {
        coin::balance<AmnisApt> (@delta_hedging)
    }

    #[view]
    public fun get_coin_view<Coin0>(): u64 {
        coin::balance<Coin0> (@delta_hedging)
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
    ) acquires SwapInformationInHyperion {
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
        
        if(!exists<SwapInformationInHyperion>(@delta_hedging)) {
            move_to(owner_signer, ans);
        } else {
            let swap_info = borrow_global_mut<SwapInformationInHyperion>(@delta_hedging);
            *swap_info = ans;
        };
    }

    #[view]
    public fun get_adr(): vector<address> acquires SwapInformationInHyperion {
        let swap_info = borrow_global<SwapInformationInHyperion>(@delta_hedging);
        swap_info.adr
    }

    #[view]
    public fun get_coin_from(): object::Object<Metadata> acquires SwapInformationInHyperion {
        let swap_info = borrow_global<SwapInformationInHyperion>(@delta_hedging);
        swap_info.coin_from
    }

    #[view]
    public fun get_coin_to(): object::Object<Metadata> acquires SwapInformationInHyperion {
        let swap_info = borrow_global<SwapInformationInHyperion>(@delta_hedging);
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


