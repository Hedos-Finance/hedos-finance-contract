module delta_hedging::interact_merkle_trade {
    use std::string::{String};

    public entry fun simple_trade_v2(
        _signer: &signer,
        _user_address: address,
        _collateral_delta: u64,
        _leverage: u64,
        _is_long: bool,
        _open: bool,
        _market_skew: bool,
        _pair: String,
    ) {
        abort(0);
    }

}