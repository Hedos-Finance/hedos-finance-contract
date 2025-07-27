module delta_hedging::token {
    use delta_hedging::white_list::{only_admin};
    use aptos_framework::aptos_account::{transfer_fungible_assets, transfer_coins};
    use aptos_framework::fungible_asset::{Metadata};
    use aptos_framework::object::{Self};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aptos_coin::AptosCoin;

    const USDC_ADDRESS: address = @USDC;
    const DELTA_HEDGING: address = @delta_hedging;

    struct BalanceUSD has key {
        amount_balance: u64
    }

    public entry fun init_balance_usdc(
        signer: &signer
    ) {
        only_admin(signer);
        let new_balance = BalanceUSD {
            amount_balance: 0
        };

        move_to(signer, new_balance);   
    }

    public fun update_balance(b: u64) acquires BalanceUSD {
        let balance = borrow_global_mut<BalanceUSD>(DELTA_HEDGING);
        balance.amount_balance = b
    }

    public entry fun transfer_usdc(
        from: &signer,
        to: address,
        amount: u64,
    ) {
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        transfer_fungible_assets(from, usdc, to, amount);
    }

    public entry fun transfer_apt(
        from: &signer,
        to: address,
        amount: u64,
    ) {
        transfer_coins<AptosCoin>(from, to, amount);
    }

    #[view]
    public fun get_usdc_balance(account: address): u64{
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let balance = primary_fungible_store::balance<Metadata>(account, usdc);
        balance
    }

    #[view]
    public fun get_balance_usdc_before(): u64 acquires BalanceUSD {
        let balance = borrow_global<BalanceUSD>(DELTA_HEDGING);
        balance.amount_balance
    }
    
}