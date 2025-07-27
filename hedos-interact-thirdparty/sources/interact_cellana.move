module delta_hedging::interact_cellana {
    use aptos_framework::object;
    use aptos_framework::object::Object;
    use aptos_framework::fungible_asset::{Metadata};
    use std::signer;

    use std::vector;

    use dex_contract::router_v3;


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

    public entry fun swap_route_entry_to_coin<ToCoin>(
        _user: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _from_token: Object<Metadata>,
        _to_tokens: vector<Object<Metadata>>,
        _is_stables: vector<bool>,
        _recipient: address,
    ) {
    }


    fun get_X_to_Y_out(
        amount: u64,
        coin_from: u8,
        coin_to: u8
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

    #[view]
    public fun get_amounts_out_amAPT_USDC_cellana(
        amount_in: u64
    ): u64 {
        get_X_to_Y_out(amount_in, AMAPT_CHOOSEN, USDC_CHOOSEN)
    }

    #[view]
    public fun get_amounts_out_APT_USDC_cellana(
        amount_in: u64
    ): u64 {
        get_X_to_Y_out(amount_in, APT_CHOOSEN, USDC_CHOOSEN)
    }

    #[view]
    public fun get_amounts_out_USDC_APT_cellana(
        amount_in: u64
    ): u64 {
        get_X_to_Y_out(amount_in, USDC_CHOOSEN, APT_CHOOSEN)
    }

    #[view]
    public fun get_amounts_out_USDC_amAPT_cellana(
        amount_in: u64
    ): u64 {
        get_X_to_Y_out(amount_in, USDC_CHOOSEN, AMAPT_CHOOSEN)
    }

    #[view]
    public fun get_amounts_out_amAPT_APT_cellana(
        amount_in: u64
    ): u64 {
        get_X_to_Y_out(amount_in, AMAPT_CHOOSEN, APT_CHOOSEN)
    }
        
    fun hyperion_swap_X_To_Y(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8
    ) {
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

        let amount_out_min = router_v3::get_batch_amount_out(
            coins,
            amount,
            x,
            y
        );

        router_v3::swap_batch(
            owner_signer,
            coins,
            x,
            y,
            amount,
            amount_out_min,
            signer::address_of(owner_signer)
        );
    }


    public entry fun swap_APT_to_USDC(signer: &signer, amount_in: u64) {
        hyperion_swap_X_To_Y(signer, amount_in, APT_CHOOSEN, USDC_CHOOSEN);
    }

    public entry fun swap_USDC_to_APT(signer: &signer, amount_in: u64) {
        hyperion_swap_X_To_Y(signer, amount_in, USDC_CHOOSEN, APT_CHOOSEN);
    }

    public entry fun swap_USDC_to_APTv2(signer: &signer, amount_in: u64, amount_out_min:u64) {
        let coins = vector::empty<address>();
        let x;
        let y;

            x = object::address_to_object<Metadata>(USDC_ADDRESS);
            y = object::address_to_object<Metadata>(APT_ADDRESS);

            coins.push_back(APT_USDC_LP_ADR);

        router_v3::swap_batch(
            signer,
            coins,
            x,
            y,
            amount_in,
            amount_out_min,
            signer::address_of(signer)
        );
    }

    public entry fun swap_amAPT_to_USDC(
        signer: &signer,
        amount: u64,
    ) {
        hyperion_swap_X_To_Y(signer, amount, AMAPT_CHOOSEN, USDC_CHOOSEN);
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
}
