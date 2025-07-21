module delta_hedging::interact_merkle_trade {
    use std::string::{String,utf8};
    use merkle::managed_trading;

    use merkle::pair_types::APT_USD;
    use merkle::fa_box::W_USDC;

    #[view]
    public fun get_size_delta_and_collateral_delta_v2(
        _collateral_delta: u64,
        _leverage: u64,
        _open: bool,
        _is_maker: bool,
        _pair: String,
    ): (u64, u64) {
        if (_pair == utf8(b"APT_USD")) {
            let numerator = 10_000;
            let denominator = 10_000;
            if (_is_maker) {
                denominator += _leverage * 4;
            }
            else {
                denominator += _leverage * 8;
            };

            let new_collateral_delta_64 = (_collateral_delta as u256) * (numerator as u256) / (denominator as u256);
            let new_collateral_delta = new_collateral_delta_64 as u64;

            let _size_delta = new_collateral_delta * _leverage;
            if (_open) {
              (_size_delta, _collateral_delta)
            } else {
                (_size_delta, new_collateral_delta)
            }

        } else {
            abort 1;
            (0, 0)
        }
    }

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
        let maker = _market_skew;
        if (_is_long) {
            maker = !maker;
        };
        
        let (size_delta, collateral_delta) = get_size_delta_and_collateral_delta_v2(_collateral_delta, _leverage, _open, maker, _pair);
        if (_pair == utf8(b"APT_USD")) {
            if (!_is_long) {
                if (_open) {
                    open_short_order<APT_USD, W_USDC>(_signer, _user_address, size_delta, collateral_delta);
                } else {
                    close_short_order<APT_USD, W_USDC>(_signer, _user_address, size_delta, collateral_delta);
                }
            } else {
                if (_open) {
                    open_long_order<APT_USD, W_USDC>(_signer, _user_address, size_delta, collateral_delta);
                } else {
                    close_long_order<APT_USD, W_USDC>(_signer, _user_address, size_delta, collateral_delta);
                }
            }
        }
        else {
            abort 1;
        };
    }

    public fun get_size_delta_and_collateral_delta(
        _collateral_delta: u64,
        _leverage: u64,
        _open: bool,
        _pair: String,
    ): (u64, u64) {
        if (_pair == utf8(b"APT_USD")) {
            let _size_delta = (_collateral_delta * 25 / 28) * _leverage;
            if (_open) {
              (_size_delta, _collateral_delta)
            } else {
                (_size_delta, (_collateral_delta * 25 / 28))
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
        _is_long: bool,
        _open: bool,
        _pair: String,
    ) {
        let taker = true;
        if (_is_long == _open) {
            taker = false;
        };
        let (size_delta, collateral_delta) = get_size_delta_and_collateral_delta(_collateral_delta, _leverage, taker, _pair);
        if (!_is_long) {
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
        } else {
            if (_open) {
                if (_pair == utf8(b"APT_USD")) {
                    open_long_order<APT_USD, W_USDC>(_signer, _user_address, size_delta, _collateral_delta);
                } else {
                    abort 1;
                }
            } else {
                if (_pair == utf8(b"APT_USD")) {
                    close_long_order<APT_USD, W_USDC>(_signer, _user_address, size_delta, collateral_delta);
                } else {
                    abort 1;
                }
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
    
    
    public entry fun open_long_order<PairType, CollateralType> (
        _signer: &signer,
        _user_address: address,
        _size_delta: u64,
        _collateral_delta: u64
    ) {
        let _price = 18446744073709551615;
        let _is_long = true;
        let _is_increase = true;
        let _is_market = true;
        let _stop_loss_trigger_price = 1;
        let _take_profit_trigger_price = 18446744073709551615;
        let _can_execute_above_price = false;
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

    public entry fun close_long_order<PairType, CollateralType> (
        _signer: &signer,
        _user_address: address,
        _size_delta: u64,
        _collateral_delta: u64
    ) {
        let _price = 18446744073709551615;
        let _is_long = true;
        let _is_increase = false;
        let _is_market = true;
        let _stop_loss_trigger_price = 1;
        let _take_profit_trigger_price = 18446744073709551615;
        let _can_execute_above_price = false;
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

    // public fun get_hehehe(
    //     _collateral_delta: u64,
    //     _leverage: u64,
    //     _open: bool,
    // ): (u64, u64) {
    //     (0, 0)
    // }
}