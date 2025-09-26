module hedos::interact_thala_pool{
    use thalaswap_v2::pool::{Self, Pool};
    use aptos_framework::object::{Self, Object};
    use std::vector;
    use std::string::{String, utf8};

    const APT_USDC_POOL_ADDRESS: address = @THALA_POOL_APT_USDC;

    fun apt_usdc(): String {
        utf8(b"APT_USDC")
    }

    const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;

    #[view]
    public fun get_lp_amount_add_liquidity(
        amount_x: u64,
        amount_y: u64,
        pair: String
    ): (u64, u64, u64) {
        let pool_obj: Object<Pool>;
        if (pair == apt_usdc()) {
            pool_obj = object::address_to_object<Pool>(APT_USDC_POOL_ADDRESS);
        } else {
            abort 1;
        };
        let assets = pool::pool_assets_metadata(pool_obj);

        if (amount_y == 0 && amount_x == 0) {
            abort 1;
        };
        
        let amounts = vector::empty<u64>();
        vector::push_back(&mut amounts, amount_x);
        vector::push_back(&mut amounts, amount_y);
            
        let preview = pool::preview_add_liquidity_weighted(pool_obj, assets, amounts);
        let (lp_amount, amount_out) = pool::add_liquidity_preview_info(preview);

        let x = *amount_out.borrow(0);
        let y = *amount_out.borrow(1);

        (lp_amount, amount_x - x, amount_y - y)
    }

    public entry fun add_liquidity(
        signer: &signer,
        amount_x: u64,
        amount_y: u64,
        pair: String
    ) {
        let pool_obj: Object<Pool>;
        if (pair == apt_usdc()) {
            pool_obj = object::address_to_object<Pool>(APT_USDC_POOL_ADDRESS);
        } else {
            abort 1;
        };

        let amounts = vector::empty<u64>();
        let (lp_amount, x, y) = get_lp_amount_add_liquidity(amount_x, amount_y, pair);
        amounts.push_back(x);
        amounts.push_back(y);            

        pool::add_liquidity_weighted_entry(
            signer,
            pool_obj,
            amounts, 
            lp_amount
        );
    }

    #[view]
    public fun get_params_remove_liquidity(
        amount: u64,
        pair: String
    ): vector<u64> {
        let pool_obj: Object<Pool>;
        if (pair == apt_usdc()) {
            pool_obj = object::address_to_object<Pool>(APT_USDC_POOL_ADDRESS);
        } else {
            abort 1;
        };
        let pool_lp_token_metadata = pool::pool_lp_token_metadata(pool_obj);
        pool::remove_liquidity_preview_info(pool::preview_remove_liquidity(pool_obj, pool_lp_token_metadata, amount))
    }

    public entry fun remove_liquidity(
        signer: &signer,
        amount: u64,
        pair: String
    ) {
        let pool_obj: Object<Pool>;
        if (pair == apt_usdc()) {
            pool_obj = object::address_to_object<Pool>(APT_USDC_POOL_ADDRESS);
        } else {
            abort 1;
        };
        let pool_lp_token_metadata = pool::pool_lp_token_metadata(pool_obj);
        let amounts = get_params_remove_liquidity(amount, pair);
        pool::remove_liquidity_entry(
            signer,
            pool_obj,
            pool_lp_token_metadata,
            amount,
            amounts
        );
    }
}