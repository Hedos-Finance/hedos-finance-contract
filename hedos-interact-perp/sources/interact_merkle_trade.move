module hedos::interact_merkle_trade {
    use std::string::{String,utf8};

    use merkle::pair_types::APT_USD;
    use merkle::pair_types::BTC_USD;
    use merkle::fa_box::W_USDC;

    use merkle::managed_trading;

    const DECIMAL_BASE: u64 = 1000_000_000_000_000;

    #[view]
    public fun apt_usd(): String {
        utf8(b"APT_USD")
    }

    #[view]
    public fun btc_usd(): String {
        utf8(b"BTC_USD")
    }

    #[view]
    public fun apt_usdc(): String {
        utf8(b"APT_USDC")
    }

    #[view]
    public fun btc_usdc(): String {
        utf8(b"BTC_USDC")
    }
    

    #[view]
    public fun get_size_delta_and_collateral_delta(
        _collateral_delta: u64,
        _leverage: u64,
        _open: bool,
        _is_maker: bool,
        _pair: String,
    ): (u64, u64) {
        if (_leverage % DECIMAL_BASE != 0) {
            let collateral_delta = _collateral_delta;
            let numerator = (collateral_delta as u128) * (_leverage as u128);
            let size_delta = (((numerator - 1) / (DECIMAL_BASE as u128)) as u64) + 1;

            return (size_delta, collateral_delta);
        };

        _leverage /= DECIMAL_BASE;

        let numerator = 10_000;
        let denominator = 10_000;
        if (_pair == apt_usdc()) {
            if (_is_maker) {
                denominator += _leverage * 4;
            } else {
                denominator += _leverage * 8;
            };
        } else if (_pair == btc_usdc()) {
            if (_is_maker) {
                denominator += _leverage * 3;
            } else {
                denominator += _leverage * 6;
            };
        } else {
            abort 1;
        };

        numerator = denominator - numerator;
        let fee = (_collateral_delta as u256) * (numerator as u256) / (denominator as u256);
        let new_collateral_delta_64 = (_collateral_delta as u256) - fee;
        let new_collateral_delta = new_collateral_delta_64 as u64;

        let _size_delta = new_collateral_delta * _leverage;
            
        if (_open) {
            (_size_delta, _collateral_delta)
        } else {
            (_collateral_delta * _leverage, _collateral_delta)
        }
    }

    public entry fun simple_trade_by_size(
        _signer: &signer,
        _user_address: address,
        _collateral_delta: u64,
        _size_delta: u64,
        _is_long: bool,
        _open: bool,
        _market_skew: bool,
        _pair: String
    ) {
        if (_pair == apt_usdc()) {
            if (!_is_long) {
                if (_open) {
                    open_short_order<APT_USD, W_USDC>(_signer, _user_address, _size_delta, _collateral_delta);
                } else {
                    close_short_order<APT_USD, W_USDC>(_signer, _user_address, _size_delta, _collateral_delta);
                }
            } else {
                if (_open) {
                    open_long_order<APT_USD, W_USDC>(_signer, _user_address, _size_delta, _collateral_delta);
                } else {
                    close_long_order<APT_USD, W_USDC>(_signer, _user_address, _size_delta, _collateral_delta);
                }
            }
        } else if (_pair == btc_usdc()) {
            if (!_is_long) {
                if (_open) {
                    open_short_order<BTC_USD, W_USDC>(_signer, _user_address, _size_delta, _collateral_delta);
                } else {
                    close_short_order<BTC_USD, W_USDC>(_signer, _user_address, _size_delta, _collateral_delta);
                }
            } else {
                if (_open) {
                    open_long_order<BTC_USD, W_USDC>(_signer, _user_address, _size_delta, _collateral_delta);
                } else {
                    close_long_order<BTC_USD, W_USDC>(_signer, _user_address, _size_delta, _collateral_delta);
                }
            }
        } else {
            abort 1;
        };

    }

    public entry fun simple_trade_by_leverage(
        _signer: &signer,
        _user_address: address,
        _collateral_delta: u64,
        _leverage: u64,
        _is_long: bool,
        _open: bool,
        _market_skew: bool,
        _pair: String
    ) {
        let maker = _market_skew;
        if (_is_long) {
            maker = !maker;
        };
        
        let (size_delta, collateral_delta) = get_size_delta_and_collateral_delta(_collateral_delta, _leverage, _open, maker, _pair);

        simple_trade_by_size(
            _signer,
            _user_address,
            collateral_delta,
            size_delta,
            _is_long,
            _open,
            _market_skew,
            _pair
        );
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
}