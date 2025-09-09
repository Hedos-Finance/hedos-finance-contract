module hedos::interact_amnis{
    use amnis::router;
    use amnis::amapt_token::AmnisApt;
    use amnis::stapt_token::StakedApt;
    use aptos_framework::coin::{Self};
    use aptos_framework::account;

    #[view]
    public fun get_stAPT_balance(addr: address): u64{
        if (account::exists_at(addr)) {
            coin::balance<StakedApt>(addr)
        } else {
            0
        }
    }

    #[view]
    public fun get_amAPT_balance(addr: address): u64{
        if (account::exists_at(addr)) {
            coin::balance<AmnisApt>(addr)
        } else {
            0
        }
    }
    
    #[view]
    public fun amnis_get_stAPT_balance(addr: address): u64{
        if (account::exists_at(addr)) {
            coin::balance<StakedApt>(addr)
        } else {
            0
        }
    }

    #[view]
    public fun amnis_get_amAPT_balance(addr: address): u64{
        if (account::exists_at(addr)) {
            coin::balance<AmnisApt>(addr)
        } else {
            0
        }
    }

    public entry fun stake(
        depositor: &signer,
        amount: u64,
        receiver: address
    ){
        // Call the stake function from the amnis router module
        router::deposit_and_stake_entry(depositor, amount, receiver);
    }

    public entry fun only_stake(
        depositor: &signer,
        amount: u64,
        receiver: address
    ){
        // Call the stake function from the amnis router module
        router::stake_entry(depositor, amount, receiver);
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