module cellana::router {
    use aptos_framework::fungible_asset::{Metadata};
    use aptos_framework::object::{Self};
    use aptos_framework::object::Object;
    
    public entry fun swap_route_entry_from_coin<FromCoin>(
        user: &signer,
        amount_in: u64,
        amount_out_min: u64,
        to_tokens: vector<Object<Metadata>>,
        is_stables: vector<bool>,
        recipient: address,
    ) {
        abort(0);
    }

     public entry fun swap_route_entry_both_coins<FromCoin, ToCoin>(
        user: &signer,
        amount_in: u64,
        amount_out_min: u64,
        to_tokens: vector<Object<Metadata>>,
        is_stables: vector<bool>,
        recipient: address,
    ) {
        abort(0);
    }

    #[view]
    public fun get_amounts_out(
        amount_in: u64,
        from_token: Object<Metadata>,
        to_tokens: vector<address>,
        is_stable: vector<bool>,
    ): u64 {
        abort(1)
    }
}