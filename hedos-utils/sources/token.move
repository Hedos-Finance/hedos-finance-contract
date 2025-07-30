module hedos::token {
    use aptos_framework::aptos_account::{transfer_fungible_assets, transfer_coins};
    use aptos_framework::fungible_asset::{Metadata};
    use aptos_framework::object::{Self};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aptos_coin::AptosCoin;

    use aptos_framework::account;
    use aptos_framework::coin::{Self};
    
    use amnis::amapt_token::AmnisApt;
    use amnis::stapt_token::StakedApt;


    const USDC_ADDRESS: address = @USDC;

    #[view]
    public fun get_usdc_balance(account: address): u64{
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        let balance = primary_fungible_store::balance<Metadata>(account, usdc);
        balance
    }
    
    #[view]
    public fun get_apt_balance(addr: address): u64 {
        if (account::exists_at(addr)) {
            coin::balance<AptosCoin>(addr)
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
    public fun get_stAPT_balance(addr: address): u64{
        if (account::exists_at(addr)) {
            coin::balance<StakedApt>(addr)
        } else {
            0
        }
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
}