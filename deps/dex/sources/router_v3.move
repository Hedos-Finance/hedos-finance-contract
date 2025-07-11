module dex_contract::router_v3 {
    use aptos_framework::fungible_asset::{Metadata};
    use aptos_framework::object::{Self};
    use aptos_framework::object::Object;

     public entry fun swap_batch_coin_directly_deposit_entry<T>(
        _user: &signer,
        _lp_path: vector<address>,
        _from_token: Object<Metadata>,
        _to_token: Object<Metadata>,
        _amount_in: u64,
        _amount_out_min: u64
    ) {
        abort(0)
    }

    public fun get_batch_amount_out(
        _lp_path: vector<address>,
        _amount_in: u64,
        _from_token: Object<Metadata>,
        _to_token: Object<Metadata>,
    ): u64 {
        0
    }

    public entry fun swap_batch(
        _user: &signer,
        _lp_path: vector<address>,
        _from_token: Object<Metadata>,
        _to_token: Object<Metadata>,
        _amount_in: u64,
        _amount_out_min: u64,
        _recipient: address,
    ) {
        abort(0);
    }
}