module oracle::oracle {
    use oracle::decimal::Decimal;

    #[view]
    public fun get_reserve_price<Coin>(): Decimal {
        abort(0)
    }
}