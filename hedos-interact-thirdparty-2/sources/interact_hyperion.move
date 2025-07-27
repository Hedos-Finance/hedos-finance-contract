module delta_hedging::interace_hyperion {

    use delta_hedging::storage;

    use std::signer;

    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self};
    use aptos_framework::aptos_coin::AptosCoin;
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

    public entry fun hyperion_swap_APT_to_USDC(
        owner_signer: &signer,
        amount: u64
    ) {
    }

    
    public entry fun swap_APT_to_USDC_hyperion<AptosCoin>(
        owner_signer: &signer,
        amount: u64
        ) {

            let amount_out_min = storage::get_apt_usdc_price_hyperion_2(
                amount, 
                1
            );

            let apt = object::address_to_object<Metadata>(APT_ADDRESS);
            let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);

            router_v3::swap_batch_coin_directly_deposit_entry<AptosCoin>(
                owner_signer,
                vector[APT_USDC_LP_ADR],
                apt,
                usdc,
                amount,
                amount_out_min
            );
        }
        
    public fun hyperion_get_amount_out_X_to_Y(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8,
        slippage_type: u8
    ): u64 {
        storage::set_swap_information_in_hyperion(
            owner_signer,
            coin_from,
            coin_to,
            slippage_type
        );

        let ans = storage::get_X_Y_price_hyperion(
            amount
        );
        ans
    }

    public entry fun hyperion_swap_X_To_Y(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8,
        slippage_type: u8
    ) {
        let amount_out_min = hyperion_get_amount_out_X_to_Y(
            owner_signer,
            amount,
            coin_from,
            coin_to,
            slippage_type
        );

        router_v3::swap_batch(
            owner_signer,
            storage::get_adr(),
            storage::get_coin_from(),
            storage::get_coin_to(),
            amount,
            amount_out_min,
            signer::address_of(owner_signer)
        );
    }
    
    #[view]
    public fun get_amount_out_hyperion(
        amount: u64,
        rev: bool
    ): u64 {
        let inp_addr;
        let oup_addr;
        if (rev) {
            inp_addr = object::address_to_object<Metadata>(USDC_ADDRESS);
            oup_addr = object::address_to_object<Metadata>(APT_ADDRESS);
        } else {
            inp_addr = object::address_to_object<Metadata>(APT_ADDRESS);
            oup_addr = object::address_to_object<Metadata>(USDC_ADDRESS);
        };
        let price = router_v3::get_batch_amount_out(
            vector[APT_USDC_LP_ADR],
            amount,
            inp_addr,
            oup_addr
        );
        price
    }

    #[view]
    public fun get_amount_in_hyperion(
        amount: u64,
        rev: bool
    ): u64 {
        let inp_addr;
        let oup_addr;
        if (rev) {
            inp_addr = object::address_to_object<Metadata>(USDC_ADDRESS);
            oup_addr = object::address_to_object<Metadata>(APT_ADDRESS);
        } else {
            inp_addr = object::address_to_object<Metadata>(APT_ADDRESS);
            oup_addr = object::address_to_object<Metadata>(USDC_ADDRESS);
        };

        let price = router_v3::get_batch_amount_in(
            vector[APT_USDC_LP_ADR],
            amount,
            inp_addr,
            oup_addr
        );
        price
    }
        
    #[view]
    public fun get_X_to_Y_out(
        amount: u64,
        coin_from: u8,
        coin_to: u8,
        slippage_type: u8
    ): u64 {
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

        let price = router_v3::get_batch_amount_out(
            coins,
            amount,
            x,
            y
        );
        price
    }
}