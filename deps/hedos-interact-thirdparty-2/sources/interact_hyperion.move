module delta_hedging::interace_hyperion {    
    public entry fun swap_APT_to_USDC_hyperion<AptosCoin>(
        owner_signer: &signer,
        amount: u64
        ) {
        abort(0);
        }

    public entry fun hyperion_swap_X_To_Y(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8,
        slippage_type: u8
    ) {
        abort(0);
    }
    
    #[view]
    public fun get_amount_out_hyperion(
        amount: u64,
        rev: bool
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
        
    #[view]
    public fun get_X_to_Y_out(
        amount: u64,
        coin_from: u8,
        coin_to: u8,
        slippage_type: u8
    ): u64 {
        0
    }
}