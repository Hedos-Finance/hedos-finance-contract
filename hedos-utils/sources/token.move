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

    use std::string::{String, utf8};


    const USDC_ADDRESS: address = @USDC;
    const WBTC_ADDRESS: address = @WBTC;
    const XBTC_ADDRESS: address = @XBTC;
    const THALA_LP_APT_USDC_ADDRESS: address = @THALA_LP_APT_USDC;
    const THALA_LP_APT_USDT_ADDRESS: address = @THALA_LP_APT_USDT;

    #[view]
    public fun usdc(): String {
        utf8(b"USDC")
    }   

    #[view]
    public fun apt(): String {
        utf8(b"APT")
    }

    #[view]
    public fun amapt(): String {
        utf8(b"AMAPT")
    }

    #[view]
    public fun wbtc(): String {
        utf8(b"WBTC")
    }

    #[view]
    public fun xbtc(): String {
        utf8(b"XBTC")
    }

    #[view]
    public fun thala_lp_apt_usdc(): String {
        utf8(b"THALA-LP-APT-USDC")
    }

    #[view]
    public fun thala_lp_apt_usdt(): String {
        utf8(b"THALA-LP-APT-USDT")
    }


    #[view]
    public fun get_balance(account: address, token: String): u64 {
        if (token == usdc()) {
            let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
            primary_fungible_store::balance<Metadata>(account, usdc)
        } else if (token == apt()) {
            if (account::exists_at(account)) {
                coin::balance<AptosCoin>(account)
            } else {
                0
            }
        // } else if (token == "AMAPT") {
        //     if (account::exists_at(account)) {
        //         coin::balance<AmnisApt>(account)
        //     } else {
        //         0
        //     }
        // } else if (token == "STAPT") {
        //     if (account::exists_at(account)) {
        //         coin::balance<StakedApt>(account)
        //     } else {
        //         0
        //     }
        } else if (token == wbtc()) {
            let wbtc = object::address_to_object<Metadata>(WBTC_ADDRESS);
            primary_fungible_store::balance<Metadata>(account, wbtc)
        } else if (token == xbtc()) {
            let xbtc = object::address_to_object<Metadata>(XBTC_ADDRESS);
            primary_fungible_store::balance<Metadata>(account, xbtc)
        } else if (token == thala_lp_apt_usdc()) {
            let thala_lp_apt_usdc = object::address_to_object<Metadata>(THALA_LP_APT_USDC_ADDRESS);
            primary_fungible_store::balance<Metadata>(account, thala_lp_apt_usdc)
        } else if (token == thala_lp_apt_usdt()) {
            let thala_lp_apt_usdt = object::address_to_object<Metadata>(THALA_LP_APT_USDT_ADDRESS);
            primary_fungible_store::balance<Metadata>(account, thala_lp_apt_usdt)
        } else {
            abort 1
        }
    }

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