module delta_hedging::interact_cellana {
    use cellana::router;
    use aptos_framework::object;
    use aptos_framework::object::Object;
    use aptos_framework::fungible_asset::{Metadata};
    use std::signer;

    use amnis::amapt_token::AmnisApt;
    use aptos_framework::aptos_coin::AptosCoin;
    const AMAPT_ADDRESS:    address = @fungible_AMAPT;
    const APT_ADDRESS:      address = @fungible_APT;
    const LZ_USDT_ADDRESS:  address = @fungible_lzUSDT;
    const USDT_ADDRESS:     address = @fungible_USDT;
    const USDC_ADDRESS:     address = @fungible_USDC;

    public entry fun swap_route_entry_to_coin<ToCoin>(
        user: &signer,
        amount_in: u64,
        amount_out_min: u64,
        from_token: Object<Metadata>,
        to_tokens: vector<Object<Metadata>>,
        is_stables: vector<bool>,
        recipient: address,
    ) {
        router::swap_route_entry_to_coin<ToCoin>(
            user,
            amount_in,
            amount_out_min,
            from_token,
            to_tokens,
            is_stables,
            recipient
        );
    }

    #[view]
    public fun get_amounts_out_amAPT_USDC_cellana(
        amount_in: u64
    ): u64 {
        let amapt = object::address_to_object<Metadata>(AMAPT_ADDRESS);
        let ans = cellana::router::get_amounts_out(
            amount_in,
            amapt,
            vector[APT_ADDRESS, USDC_ADDRESS],
            vector[true, false]
        );
        ans
    }

    #[view]
    public fun get_amounts_out_APT_USDC_cellana(
        amount_in: u64
    ): u64 {
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let ans = cellana::router::get_amounts_out(
            amount_in,
            apt,
            vector[USDC_ADDRESS],
            vector[false]
        );
        ans
    }

    #[view]
    public fun get_amounts_out_USDC_APT_cellana(
        amount_in: u64
    ): u64 {
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let ans = cellana::router::get_amounts_out(
            amount_in,
            usdc,
            vector[APT_ADDRESS],
            vector[false]
        );
        ans
    }

    #[view]
    public fun get_amounts_out_USDC_amAPT_cellana(
        amount_in: u64
    ): u64 {
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let ans = cellana::router::get_amounts_out(
            amount_in,
            usdc,
            vector[APT_ADDRESS, AMAPT_ADDRESS],
            vector[false, true]
        );
        ans
    }

    #[view]
    public fun get_amounts_out_amAPT_APT_cellana(
        amount_in: u64
    ): u64 {
        let amapt = object::address_to_object<Metadata>(AMAPT_ADDRESS);
        let ans = cellana::router::get_amounts_out(
            amount_in,
            amapt,
            vector[APT_ADDRESS],
            vector[true]
        );
        ans
    }

    public entry fun swap_APT_to_USDC(signer: &signer, amount_in: u64) {
        assert!(amount_in > 0, 0);

        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let amount_out_min = get_amounts_out_APT_USDC_cellana(amount_in);
        router::swap_route_entry_from_coin<AptosCoin>(
            signer,
            amount_in,
            amount_out_min,
            vector[usdc],
            vector[false],
            signer::address_of(signer)
        );
    }

    public entry fun swap_USDC_to_APT(signer: &signer, amount_in: u64) {
        assert!(amount_in > 0, 0);

        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let amount_out_min = get_amounts_out_USDC_APT_cellana(amount_in);
        router::swap_route_entry_to_coin<AptosCoin>(
            signer,
            amount_in,
            amount_out_min,
            usdc,
            vector[apt],
            vector[false],
            signer::address_of(signer)
        );
    }

    public entry fun swap_USDC_to_APTv2(signer: &signer, amount_in: u64, amount_out_min:u64) {
        assert!(amount_in > 0, 0);

        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);

        router::swap_route_entry_to_coin<AptosCoin>(
            signer,
            amount_in,
            amount_out_min,
            usdc,
            vector[apt],
            vector[false],
            signer::address_of(signer)
        );
    }

    public entry fun swap_amAPT_to_USDC(
        signer: &signer,
        amount: u64,
    ) {
        assert!(amount > 0, 0);
        
        let amount_out_min = 0;

        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        router::swap_route_entry_from_coin<AmnisApt>(
            signer,
            amount,
            amount_out_min,
            vector[apt, usdc],
            vector[true, false],
            signer::address_of(signer)
        );
    }

    fun hyperion_swap_X_To_Y(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8
    ) {
        abort 1;
    }
    
    fun get_X_to_Y_out(
        amount: u64,
        coin_from: u8,
        coin_to: u8
    ): u64 {
        0
    }

    #[view]
    public fun get_amount_in_hyperion(
        amount: u64,
        rev: bool
    ): u64 {
        0
    }
    
}