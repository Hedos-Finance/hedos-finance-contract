module stake_package::stake_controller {
    use amnis::router;
    use amnis::amapt_token::AmnisApt;
    use amnis::stapt_token::StakedApt;

    use aptos_framework::coin::{Self};
    use aptos_framework::account;

    #[view]
    public fun amnis_get_stAPT_balance(
        addr: address
        ) : u64 {
        if (account::exists_at(addr)) {
            coin::balance<StakedApt>(addr)
        } else {
            0
        }
    }

    #[view]
    public fun amnis_get_amAPT_balance(
        addr: address
        ) : u64 {
        if (account::exists_at(addr)) {
            coin::balance<AmnisApt>(addr)
        } else {
            0
        }
    }

    #[view]
    public fun price_stAPT(): u64 {
        amnis::stapt_token::stapt_price()
    }

    public entry fun stake(
        depositor: &signer,
        amount: u64,
        receiver: address
    ) {
        router::deposit_and_stake_entry(depositor, amount, receiver);
    }

    public entry fun unstake_amAPT(
        user: &signer,
        amount: u64,
        receiver: address
    ) {
        router::unstake_entry(
            user,
            amount,
            receiver
        );
    }

    
}