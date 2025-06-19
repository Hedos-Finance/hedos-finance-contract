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
    public fun get_amounts_out_APT_USDC_cellana(
        amount_in: u64
    ): u64 {
        let amapt = object::address_to_object<Metadata>(AMAPT_ADDRESS);
        let ans = cellana::router::get_amounts_out(
            amount_in,
            amapt,
            vector[APT_ADDRESS, LZ_USDT_ADDRESS, USDT_ADDRESS, USDC_ADDRESS],
            vector[true, false, true, true]
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
        
        let amount_out_min = get_amounts_out_APT_USDC_cellana(amount);

        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let lz_usdt = object::address_to_object<Metadata>(LZ_USDT_ADDRESS);
        let usdt = object::address_to_object<Metadata>(USDT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        router::swap_route_entry_from_coin<AmnisApt>(
            signer,
            amount,
            amount_out_min,
            vector[apt, lz_usdt, usdt, usdc],
            vector[true, false, true, true],
            signer::address_of(signer)
        );
    }

}
