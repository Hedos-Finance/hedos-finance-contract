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

    const APT_USDT_LP_ADR: address = @hyper_fungible_APT_USDT_LP;
    const USDT_USDC_LP_ADR: address = @hyper_fungible_USDT_USDC_LP;
    const AMAPT_APT_LP_ADR: address = @hyper_fungible_AMAPT_APT_LP;
    const APT_USDC_LP_ADR:  address = @hyper_fungible_APT_USDC_LP;

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;
    
    use amnis::amapt_token::AmnisApt;

    fun get_data(coin_from: u8, coin_to: u8):(vector <address>, Object<Metadata>, Object<Metadata>) {
        let coins = vector::empty<address>();
        let x;
        let y;
        
        if (coin_from == USDC_CHOOSEN) {
            x = object::address_to_object<Metadata>(USDC_ADDRESS);
            y = object::address_to_object<Metadata>(APT_ADDRESS);

            coins.push_back(APT_USDC_LP_ADR);

            if (coin_to == AMAPT_CHOOSEN) {
                y = object::address_to_object<Metadata>(AMAPT_ADDRESS);

                coins.push_back(AMAPT_APT_LP_ADR);
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
        } else {
            x = object::address_to_object<Metadata>(AMAPT_ADDRESS);
            y = object::address_to_object<Metadata>(APT_ADDRESS);

            coins.push_back(AMAPT_APT_LP_ADR);

            if (coin_to == USDC_CHOOSEN) {
                y = object::address_to_object<Metadata>(USDC_ADDRESS);
                coins.push_back(APT_USDC_LP_ADR);
            };
        };

        (coins, x, y)
    }

    public entry fun hyperion_swap_X_To_Y(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8
    ) {
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);

        if (coin_from == USDC_CHOOSEN) {
            let amount_out_min = get_X_to_Y_out(amount, USDC_CHOOSEN, APT_CHOOSEN);
            router_v3::swap_batch_directly_deposit(
                owner_signer,
                vector[APT_USDC_LP_ADR],
                usdc,
                apt,
                amount,
                amount_out_min
            );
        } else if (coin_from == APT_CHOOSEN) {
            let (coins, x, y) = get_data(coin_from, coin_to);
            let amount_out_min = get_X_to_Y_out(amount, coin_from, coin_to);

            router_v3::swap_batch_coin_directly_deposit_entry<AptosCoin>(
                owner_signer,
                coins,
                x,
                y,
                amount,
                amount_out_min
            );
        } else if (coin_from == AMAPT_CHOOSEN) {
            let (coins, x, y) = get_data(coin_from, coin_to);
            let amount_out_min = get_X_to_Y_out(amount, coin_from, coin_to);

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