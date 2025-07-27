module delta_hedging::interact_aries {
    struct BorrowStatistics<phantom Coin0> has key, copy, store, drop{
        data: BorrowStatistic
    }

    struct BorrowStatistic has key, store, drop, copy {
        Collateral_Factor: u64,
        Liquidation_Ratio: u64,
        Borrow_Factor: u64
    }

    public entry fun register_user(
        account: &signer
    ) {
        abort(0);
    }
    
    #[view]
    public fun get_price<Coin0>(): u128 {
        0
    }

    #[view]
    public fun total_lending<Coin0>(account: address): u64 {
        0
    }

    #[view]
    public fun total_loaning<Coin0>(account: address): u128 {
        0
    }

    public entry fun initialize<Coin0>(
        owner_signer: &signer
    ) {
        abort(0);
    }

    public entry fun deposit<Coin0>(
        owner_signer: &signer,
        amount: u64,
        repay_only: bool
    ) {
        abort(0);
    }

    public entry fun withdraw<Coin0>(
        owner_signer: &signer,
        amount: u64,
        allow_borrow: bool
    ) {
        abort(0);
    }

    public entry fun deposit_fa<Coin0>(
        owner_signer: &signer,
        input_amount: u64
    ) {
        abort(0);
    }

    public entry fun withdraw_fa<Coin0>(
        owner_signer: &signer,
        input_amount: u64,
        allow_borrow: bool
    ) {
        abort(0);
    }

    public entry fun repay<Coin1>(
        owner_signer: &signer,
        repay_amount_want: u128
    ) {
        abort(0);
    }

    // can use with only pair <USDC/APT>
    public fun deposit_and_borrow<Coin0, Coin1>(
        _owner_signer: &signer,
        input_amount: u64,
        collateral_want: u64
    ): (u64, u64) {
        (0, 0)
    }

    #[view]
    public fun get_borrow_amount<Coin0, Coin1>(
        input_amount: u64,
        collateral_want: u64
    ): (u64, u64) {
        (0, 0)
    }
}