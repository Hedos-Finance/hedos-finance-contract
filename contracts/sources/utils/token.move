module delta_hedging::token {
    use aptos_framework::aptos_account::{transfer_fungible_assets};
    use aptos_framework::fungible_asset::{Metadata};
    use aptos_framework::object::{Self};
    use aptos_framework::primary_fungible_store;

    const USDC_ADDRESS: address = @USDC;

    public entry fun transfer_usdc(
        from: &signer,
        to: address,
        amount: u64,
    ) {
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        transfer_fungible_assets(from, usdc, to, amount);
    }

    #[view]
    public fun get_usdc_balance(account: address): u64{
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let balance = primary_fungible_store::balance<Metadata>(account, usdc);
        balance
    }

    
}