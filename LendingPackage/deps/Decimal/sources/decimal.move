module decimal::decimal {
    struct Decimal has copy, drop, store {
        dummy_field: u64,
    }

    public fun round_u64(liuliu: Decimal): u64 {
        abort(0)
    }

    public fun raw(liuliu: Decimal): u128 {
        abort(0)
    }

    public fun scaling_factor(): u128 {
        abort(0)
    }
}