module merkle::managed_trading {
    public entry fun place_order_v3<PairType, CollateralType>(
        _signer: &signer,
        _user_address: address,
        _size_delta: u64,
        _collateral_delta: u64,
        _price: u64,
        _is_long: bool,
        _is_increase: bool,
        _is_market: bool,
        _stop_loss_trigger_price: u64,
        _take_profit_trigger_price: u64,
        _can_execute_above_price: bool,
        _referrer: address
    ) {
        abort 0;
    }
}