module delta_hedging::interact_amnis{
    #[view]
    public fun amnis_get_stAPT_balance(addr: address): u64{
        0
    }

    #[view]
    public fun amnis_get_amAPT_balance(addr: address): u64{
        0
    }

    public entry fun stake(
        depositor: &signer,
        amount: u64,
        receiver: address
    ){
        abort(0);
    }

    public entry fun unstake_amAPT(
        user: &signer,
        amount: u64,
        receiver: address
    ){
        abort(0);
    }

    #[view]
    public fun price_stAPT(): u64 {
        0
    }
}