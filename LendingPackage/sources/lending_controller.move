module lending_package::lending_controller {
    use std::signer;
    use std::string;

    use oracle::oracle;
    use decimal::decimal;

    use aries::controller;
    use aries::profile;

    const NAME_BYTES:       vector<u8>  = x"4d61696e204163636f756e74";
    const USDC_Multiplier:  u128        = 1000000000000;               // 1e12
    const APT_Multiplier:   u128        = 10000000000;                 // 1e10
    const Multiplier:       u128        = 1000000;                     // 1e6
    const Multiplier_2:     u128        = 100000000;                   // 1e8
    const Max_Multiplier:   u128        = 100000000000000000000000000; // 1e26

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
        controller::register_user(account, NAME_BYTES);
    }
    
    #[view]
    public fun get_price<Coin0>(): u128 {
        let ans = decimal::raw(oracle::get_reserve_price<Coin0>());
        ans
    }

    #[view]
    public fun get_decimal_price<Coin0>(): decimal::Decimal {
        let ans = oracle::get_reserve_price<Coin0>();
        ans
    }

    #[view]
    public fun get_borrow_statistic<Coin0>(): BorrowStatistic acquires BorrowStatistics {
        let bs_ref = borrow_global<BorrowStatistics<Coin0>>(@main_vault);
        bs_ref.data
    }

    #[view]
    public fun total_lending<Coin0>(account: address): u64 {
        let (_, total_lending) = profile::profile_deposit<Coin0>(
            account,
            string::utf8(NAME_BYTES)
        );
        total_lending
    }

    #[view]
    public fun total_loaning<Coin0>(account: address): u128 {
        let (_, total_loaning) = profile::profile_loan<Coin0>(
            account,
            string::utf8(NAME_BYTES)
        );
        total_loaning * Multiplier_2 / Max_Multiplier
    }

    public entry fun initialize<Coin0>(
        owner_signer: &signer
    ) {
        let owner = signer::address_of(owner_signer);
        
        if (!exists<BorrowStatistics<Coin0>>(owner)) {
            let new_bs = BorrowStatistics<Coin0> {
                data: BorrowStatistic {
                    Collateral_Factor: 0,
                    Liquidation_Ratio: 0,
                    Borrow_Factor: 0
                }
            };
            move_to<BorrowStatistics<Coin0>>(owner_signer, new_bs);
        }
    }

    public entry fun set_borrow_statistics<Coin0>(
        owner_signer: &signer,
        collateral_factor: u64,
        liquidation_ratio: u64,
        borrow_factor: u64
    ) acquires BorrowStatistics {
        let owner = signer::address_of(owner_signer);
    
        let bs_ref = borrow_global_mut<BorrowStatistics<Coin0>>(owner);
        bs_ref.data = BorrowStatistic {
            Collateral_Factor: collateral_factor,
            Liquidation_Ratio: liquidation_ratio,
            Borrow_Factor: borrow_factor
        };
    }

    public entry fun deposit<Coin0>(
        owner_signer: &signer,
        amount: u64,
        repay_only: bool
    ) {
        controller::deposit<Coin0>(
            owner_signer,
            NAME_BYTES,
            amount,
            repay_only
        );
    }

    public entry fun withdraw<Coin0>(
        owner_signer: &signer,
        amount: u64,
        allow_borrow: bool
    ) {
        controller::withdraw<Coin0>(
            owner_signer,
            NAME_BYTES,
            amount,
            allow_borrow
        );
    }

    public entry fun deposit_fa<Coin0>(
        owner_signer: &signer,
        input_amount: u64
    ) {
        controller::deposit_fa<Coin0>(
            owner_signer,
            NAME_BYTES,
            input_amount
        );
    }

    public entry fun withdraw_fa<Coin0>(
        owner_signer: &signer,
        input_amount: u64,
        allow_borrow: bool
    ) {
        controller::withdraw_fa<Coin0>(
            owner_signer,
            NAME_BYTES,
            input_amount,
            allow_borrow
        );
    }

    public entry fun repay<Coin1>(
        owner_signer: &signer,
        repay_amount_want: u128
    ) {
        controller::deposit<Coin1>(
            owner_signer,
            NAME_BYTES,
            (repay_amount_want) as u64,
            true
        );
    }

    // can use with only pair <USDC/APT>
    public fun deposit_and_borrow<Coin0, Coin1>(
        _owner_signer: &signer,
        input_amount: u64,
        collateral_want: u64
    ): (u64, u64) {

        let coin0_price = get_price<Coin0>();
        let coin1_price = get_price<Coin1>() * 10000;

        let borrow_amount = (input_amount as u128) 
                            * (coin0_price as u128) 
                            * (collateral_want as u128) 
                            / (coin1_price as u128);

        (input_amount, borrow_amount as u64)
    }

    #[view]
    public fun get_borrow_amount<Coin0, Coin1>(
        input_amount: u64,
        collateral_want: u64
    ): (u64, u64) {

        let coin0_price = get_price<Coin0>();
        let coin1_price = get_price<Coin1>() * 10000;

        let borrow_amount = (input_amount as u128) 
                            * (coin0_price as u128) 
                            * (collateral_want as u128) 
                            / (coin1_price as u128);

        (input_amount, borrow_amount as u64)
    }

    public entry fun deposit_and_borrow_by_rate<Coin0, Coin1>(
        owner_signer: &signer,
        input_amount: u64,
        collateral_want: u64
    ) {

        let coin0_price = get_price<Coin0>();
        let coin1_price = get_price<Coin1>() * 10000;

        let borrow_amount = (input_amount as u128) 
                            * (coin0_price as u128) 
                            * (collateral_want as u128) 
                            / (coin1_price as u128);
        
        controller::deposit_fa<Coin0>(
            owner_signer,
            NAME_BYTES,
            input_amount
        );
        
        controller::withdraw<Coin1>(
            owner_signer,
            NAME_BYTES,
            borrow_amount as u64,
            true
        );
    }
}