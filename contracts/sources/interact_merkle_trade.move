module fauz::interact_merkle_trade {
    use std::string::{String,utf8};
    use merkle::managed_trading;

    use merkle::pair_types::APT_USD;
    use merkle::fa_box::W_USDC;

    public fun get_size_delta_and_collateral_delta(
        _collateral_delta: u64,
        _leverage: u64,
        _open: bool,
        _pair: String,
    ): (u64, u64) {
        if (_pair == utf8(b"APT_USD")) {
            let _size_delta = (_collateral_delta * 50 / 53) * _leverage;
            if (_open) {
                (_size_delta, _collateral_delta)
            } else {
                (_size_delta, (_collateral_delta * 50 / 53))
            }
        } else {
            abort 1;
            (0, 0)
        }
    }

    public entry fun simple_trade(
        _signer: &signer,
        _user_address: address,
        _collateral_delta: u64,
        _leverage: u64,
        _open: bool,
        _pair: String,
    ) {
        let (size_delta, collateral_delta) = get_size_delta_and_collateral_delta(_collateral_delta, _leverage, _open, _pair);
        if (_open) {
            if (_pair == utf8(b"APT_USD")) {
                open_short_order<APT_USD, W_USDC>(_signer, _user_address, size_delta, _collateral_delta);
            } else {
                abort 1;
            }
        } else {
            if (_pair == utf8(b"APT_USD")) {
                close_short_order<APT_USD, W_USDC>(_signer, _user_address, size_delta, collateral_delta);
            } else {
                abort 1;
            }
        }
    }
    
    public entry fun open_short_order<PairType, CollateralType> (
        _signer: &signer,
        _user_address: address,
        _size_delta: u64,
        _collateral_delta: u64
    ) {
        let _price = 1;
        let _is_long = false;
        let _is_increase = true;
        let _is_market = true;
        let _stop_loss_trigger_price = 18446744073709551615;
        let _take_profit_trigger_price = 1;
        let _can_execute_above_price = true;
        let _referrer = @0x0000000000000000000000000000000000000000;
        managed_trading::place_order_v3<PairType, CollateralType> (
            _signer,
            _user_address,
            _size_delta,
            _collateral_delta,
            _price,
            _is_long,
            _is_increase,
            _is_market,
            _stop_loss_trigger_price,
            _take_profit_trigger_price,
            _can_execute_above_price,
            _referrer
        );
    }

    public entry fun close_short_order<PairType, CollateralType> (
        _signer: &signer,
        _user_address: address,
        _size_delta: u64,
        _collateral_delta: u64
    ) {
        let _price = 1;
        let _is_long = false;
        let _is_increase = false;
        let _is_market = true;
        let _stop_loss_trigger_price = 18446744073709551615;
        let _take_profit_trigger_price = 1;
        let _can_execute_above_price = true;
        let _referrer = @0x0000000000000000000000000000000000000000;
        managed_trading::place_order_v3<PairType, CollateralType> (
            _signer,
            _user_address,
            _size_delta,
            _collateral_delta,
            _price,
            _is_long,
            _is_increase,
            _is_market,
            _stop_loss_trigger_price,
            _take_profit_trigger_price,
            _can_execute_above_price,
            _referrer
        );        
    }

    
    public fun get_hehehe(
        _collateral_delta: u64,
        _leverage: u64,
        _open: bool,
    ): (u64, u64) {
        (0, 0)
    }
}