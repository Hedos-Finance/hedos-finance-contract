module swap_package::swap_controller {

    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self};
    use aptos_framework::aptos_coin::AptosCoin;

    use dex_contract::router_v3;

    const APT_ADDRESS:          address = @hyper_fungible_APT;
    const USDC_ADDRESS:         address = @hyper_fungible_USDC;

    const APT_USDC_LP_ADR:      address = @hyper_fungible_APT_USDC_LP;

    public entry fun hyper_swap_APT_to_USDC(
        owner: &signer,
        amount: u64
    ) {
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);

        let amount_out_min = router_v3::get_batch_amount_out(
            vector[APT_USDC_LP_ADR],
            amount,
            apt,
            usdc
        );

        router_v3::swap_batch_coin_directly_deposit_entry<AptosCoin>(
            owner,
            vector[APT_USDC_LP_ADR],
            apt,
            usdc,
            amount,
            amount_out_min
        );
    }

    public entry fun hyper_swap_USDC_to_APT(
        owner: &signer,
        amount: u64
    ) {
        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);

        let amount_out_min = router_v3::get_batch_amount_out(
            vector[APT_USDC_LP_ADR],
            amount,
            usdc,
            apt
        );

        router_v3::swap_batch_directly_deposit(
            owner,
            vector[APT_USDC_LP_ADR],
            usdc,
            apt,
            amount,
            amount_out_min
        )
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
}