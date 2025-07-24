module delta_hedging::interact_amnis{
    use amnis::router;

    public entry fun stake(
        depositor: &signer,
        amount: u64,
        receiver: address
    ){
        // Call the stake function from the amnis router module
        router::deposit_and_stake_entry(depositor, amount, receiver);
    }

    public entry fun unstake_amAPT(
        user: &signer,
        amount: u64,
        receiver: address
    ){
        router::unstake_entry(
            user,
            amount,
            receiver
        );
    }

    #[view]
    public fun price_stAPT(): u64 {
        // Call the stapt_price function from the amnis module
        amnis::stapt_token::stapt_price()
    }
}