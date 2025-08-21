module hedos::interact_hyperion {
    use aptos_framework::aptos_coin::AptosCoin;

    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self, Object};
    use aptos_std::vector;

    use dex_contract::router_v3;

    const LS_V0: u8 = 0;
    const LS_V05: u8 = 5;

    const AMAPT_ADDRESS:    address = @hyper_fungible_AMAPT;
    const APT_ADDRESS:      address = @hyper_fungible_APT;
    const LZ_USDT_ADDRESS:  address = @hyper_fungible_lzUSDT;
    const USDT_ADDRESS:     address = @hyper_fungible_USDT;
    const USDC_ADDRESS:     address = @hyper_fungible_USDC;
    const WBTC_ADDRESS:     address = @hyper_fungible_WBTC;
    const XBTC_ADDRESS:     address = @hyper_fungible_XBTC;

    const APT_USDT_LP_ADR: address = @hyper_fungible_APT_USDT_LP;
    const USDT_USDC_LP_ADR: address = @hyper_fungible_USDT_USDC_LP;
    const AMAPT_APT_LP_ADR: address = @hyper_fungible_AMAPT_APT_LP;
    const APT_USDC_LP_ADR:  address = @hyper_fungible_APT_USDC_LP;
    const USDC_XBTC_LP_ADR: address = @hyper_fungible_USDC_XBTC_LP;
    const USDC_WBTC_LP_ADR: address = @hyper_fungible_USDC_WBTC_LP;

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;
    const XBTC_CHOOSEN: u8 = 4;
    const WBTC_CHOOSEN: u8 = 5;
    
    use amnis::amapt_token::AmnisApt;

    fun get_data(coin_from: u8, coin_to: u8):(vector <address>, Object<Metadata>, Object<Metadata>) {
        let coins = vector::empty<address>();
        let x;
        let y;
        
        if (coin_from == USDC_CHOOSEN) {
            x = object::address_to_object<Metadata>(USDC_ADDRESS);
            if (coin_to == APT_CHOOSEN || coin_to == AMAPT_CHOOSEN) {                
                y = object::address_to_object<Metadata>(APT_ADDRESS);

                coins.push_back(APT_USDC_LP_ADR);

                if (coin_to == AMAPT_CHOOSEN) {
                    y = object::address_to_object<Metadata>(AMAPT_ADDRESS);

                    coins.push_back(AMAPT_APT_LP_ADR);
                };
            } else if (coin_to == XBTC_CHOOSEN) {
                y = object::address_to_object<Metadata>(XBTC_ADDRESS);
                coins.push_back(USDC_XBTC_LP_ADR);
            } else if (coin_to == WBTC_CHOOSEN) {
                y = object::address_to_object<Metadata>(WBTC_ADDRESS);
                coins.push_back(USDC_WBTC_LP_ADR);
            } else {
                abort 1;
            };
        } else if (coin_from == APT_CHOOSEN) {
            x = object::address_to_object<Metadata>(APT_ADDRESS);
            
            if(coin_to == USDC_CHOOSEN) {
                y = object::address_to_object<Metadata>(USDC_ADDRESS);
                coins.push_back(APT_USDC_LP_ADR);
            } else {
                y = object::address_to_object<Metadata>(AMAPT_ADDRESS);
                coins.push_back(AMAPT_APT_LP_ADR);
            };
        } else if (coin_from == AMAPT_CHOOSEN) {
            x = object::address_to_object<Metadata>(AMAPT_ADDRESS);
            y = object::address_to_object<Metadata>(APT_ADDRESS);

            coins.push_back(AMAPT_APT_LP_ADR);

            if (coin_to == USDC_CHOOSEN) {
                y = object::address_to_object<Metadata>(USDC_ADDRESS);
                coins.push_back(APT_USDC_LP_ADR);
            };
        } else if (coin_from == XBTC_CHOOSEN) {
            x = object::address_to_object<Metadata>(XBTC_ADDRESS);
            y = object::address_to_object<Metadata>(USDC_ADDRESS);
            coins.push_back(USDC_XBTC_LP_ADR);
        } else if (coin_from == WBTC_CHOOSEN) {
            x = object::address_to_object<Metadata>(WBTC_ADDRESS);
            y = object::address_to_object<Metadata>(USDC_ADDRESS);
            coins.push_back(USDC_WBTC_LP_ADR);
        } else {
            abort 1;
        };

        (coins, x, y)
    }

    public entry fun hyperion_swap_X_To_Y(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8
    ) {
        let (coins, x, y) = get_data(coin_from, coin_to);
        let amount_out_min = get_X_to_Y_out(amount, coin_from, coin_to);

        if (coin_from == USDC_CHOOSEN || coin_from == XBTC_CHOOSEN || coin_from == WBTC_CHOOSEN) {
            router_v3::swap_batch_directly_deposit(
                owner_signer,
                coins,
                x,
                y,
                amount,
                amount_out_min
            );
        } else if (coin_from == APT_CHOOSEN) {
            router_v3::swap_batch_coin_directly_deposit_entry<AptosCoin>(
                owner_signer,
                coins,
                x,
                y,
                amount,
                amount_out_min
            );
        } else if (coin_from == AMAPT_CHOOSEN) {
            router_v3::swap_batch_coin_directly_deposit_entry<AmnisApt>(
                owner_signer,
                coins,
                x,
                y,
                amount,
                amount_out_min
            );
        } else {
            abort 1;
        };
    }

    #[view]
    public fun get_X_to_Y_out(
        amount: u64,
        coin_from: u8,
        coin_to: u8
    ): u64 {
        let (coins, x, y) = get_data(coin_from, coin_to);

        let price = router_v3::get_batch_amount_out(
            coins,
            amount,
            x,
            y
        );
        price
    }

    #[view]
    public fun get_amount_in(
        amount: u64,
        coin_from: u8,
        coin_to: u8
    ): u64 {
        let (coins, x, y) = get_data(coin_from, coin_to);

        let price = router_v3::get_batch_amount_in(
            coins,
            amount,
            x,
            y
        );
        price
    }
        
}