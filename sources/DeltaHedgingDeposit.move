module hello_aptos_network::DeltaHedgingDeposit {

    use hello_aptos_network::DeltaHedgingStakingV2Storage;

    use std::signer;
    use std::string;
    use std::vector;

    use aptos_std::table;
    use aptos_std::type_info::{Self, TypeInfo};


    use aptos_framework::object::{Self};
    use aptos_framework::aptos_coin::AptosCoin;

    use wrapped_coins::wrapped_coins::WrappedUSDC;
    use oracle::oracle;
    use decimal::decimal;


    // Aries framework
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////

    use aries::controller;
    use aries::profile;

    const NAME_BYTES: vector<u8> = x"4d61696e204163636f756e74";
    const USDC_Multiplier: u128 = 1000000000000; // 1e12
    const APT_Multiplier: u128 = 10000000000; // 1e10
    const Multiplier: u128 = 1000000; // 1e6
    const Multiplier_2: u128 = 100000000; // 1e8

    const Max_Multiplier: u128 = 1000000000000000000000000; // 1e27

    struct BorrowStatistics<phantom Coin0> has key, copy, store, drop{
        data: BorrowStatistic
    }

    struct BorrowStatistic has key, store, drop, copy {
        Collateral_Factor: u8, 
        Liquidation_Ratio: u8,
        Borrow_Factor: u8
    }

    public entry fun initialize<Coin0>(
        owner_signer: &signer
    ) {
    let owner = signer::address_of(owner_signer);
    assert!(owner == DeltaHedgingStakingV2Storage::get_admin_view(), 0);
    
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
        collateral_factor: u8,
        liquidation_ratio: u8,
        borrow_factor: u8
    ) acquires BorrowStatistics {
        let owner = signer::address_of(owner_signer);
        assert!(owner == DeltaHedgingStakingV2Storage::get_admin_view(), 0);
    
        let bs_ref = borrow_global_mut<BorrowStatistics<Coin0>>(owner);
        bs_ref.data = BorrowStatistic {
            Collateral_Factor: collateral_factor,
            Liquidation_Ratio: liquidation_ratio,
            Borrow_Factor: borrow_factor
        };
    }

    #[view]
    public fun get_borrow_statistic<Coin0>(): BorrowStatistic acquires BorrowStatistics {
        let bs_ref = borrow_global<BorrowStatistics<Coin0>>(@hello_aptos_network);
        bs_ref.data
    }

    #[view]
    public fun total_lending_2<Coin0>(): u64 {
        let (total_collateral, total_lending) = profile::profile_deposit<Coin0>(
            @hello_aptos_network,
            string::utf8(NAME_BYTES)
        );
        total_lending
    }

    #[view]
    public fun total_loaning_2<Coin0>(): u128 {
        let (total_collateral, total_loaning) = profile::profile_loan<Coin0>(
            @hello_aptos_network,
            string::utf8(NAME_BYTES)
        );
        total_loaning
    }

    public entry fun deposit_2<Coin0>(
        owner_signer: &signer,
        amount: u64,
        repay_only: bool
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);

        controller::deposit<Coin0>(
            owner_signer,
            NAME_BYTES,
            amount,
            repay_only
        );
    }

    public entry fun withdraw_2<Coin0>(
        owner_signer: &signer,
        amount: u64,
        allow_borrow: bool
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);

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
        assert!(input_amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);

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
        assert!(input_amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);

        controller::withdraw_fa<Coin0>(
            owner_signer,
            NAME_BYTES,
            input_amount,
            allow_borrow
        );

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

    //wrong function
    #[view]
    public fun get_price_2<Coin0>(): u64 {
        let ans = oracle::get_reserve_price<Coin0>();
        let ans_rounded = decimal::round_u64(ans);
        ans_rounded
    }

    // can use with only pair <USDC/APT>
    public entry fun deposit_and_borrow<Coin0, Coin1>(
        owner_signer: &signer,
        input_amount: u64,
        collateral_want: u8
    ) acquires BorrowStatistics {
        assert!(input_amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);
        assert!(collateral_want <= get_borrow_statistic<Coin1>().Collateral_Factor, 3);

        let coin0_price = get_price<Coin0>();
        let coin1_price = get_price<Coin1>() * 100;
        
        let margin_amount_in_USD = (input_amount as u128) 
                                * (coin0_price as u128) 
                                * (get_borrow_statistic<Coin0>().Collateral_Factor as u128) 
                                / USDC_Multiplier
                                / Multiplier
                                / 100;
        assert!(margin_amount_in_USD >= 5, 4);
        
        controller::deposit_fa<Coin0>(
            owner_signer,
            NAME_BYTES,
            input_amount
        );

        let borrow_amount = (input_amount as u128) 
                            * (coin0_price as u128) 
                            * (collateral_want as u128) 
                            * (get_borrow_statistic<Coin0>().Collateral_Factor as u128)
                            * (100 as u128) // apt = 1e8, usdc = 1e6
                            / (coin1_price as u128)
                            / (100 as u128)  // percentage for collateral
                            / (100 as u128); // percentage for want

        controller::withdraw<Coin1>(
            owner_signer,
            NAME_BYTES,
            borrow_amount as u64,
            true
        );
    }

    // can use with only APT
    // multiplier: 1 apt = 1e27 repay_amount_want
    public entry fun repay<Coin1>(
        owner_signer: &signer,
        repay_amount_want: u128
    ) {
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);
        let total_coin1_loaning = total_loaning_2<Coin1>();
        assert!(repay_amount_want <= total_coin1_loaning, 2);
        controller::deposit<Coin1>(
            owner_signer,
            NAME_BYTES,
            (repay_amount_want * Multiplier_2 / Max_Multiplier) as u64, // convert to 1e8
            true
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////
    
    //old code
    #[view]
    public fun total_lending(): u64 {
        let (total_collateral, total_apt_lending) = profile::profile_deposit<AptosCoin>(
            @hello_aptos_network,
            string::utf8(NAME_BYTES)
        );
        total_apt_lending
    }

    #[view]
    public fun total_loaning(): u128 {
        let (total_collateral, total_apt_loaning) = profile::profile_loan<AptosCoin>(
            @hello_aptos_network,
            string::utf8(NAME_BYTES)
        );
        total_apt_loaning
    }

    // cai true/false trong truong hop deposit la option co/khong gui tai san lam collateral
    // false: 
    // user co khoan vay -> uu tien tra no
    // tien thua tu vc tra no / ng dung khong no truoc do -> collateral
    // true:
    // user co khoan vay -> tra no
    // tien thua tu vc tra no / nguoi dung khong no truoc do -> tra lai cho user

    public entry fun deposit(
        owner_signer: &signer,
        amount: u64
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);
        assert!(amount <= DeltaHedgingStakingV2Storage::get_total_apt_view(), 2);

        controller::deposit<AptosCoin>(
            owner_signer,
            NAME_BYTES,
            amount,
            false
        );
    }

    // true / false trong truong hop withdraw la option co/khong rut qua phan da deposit
    // false:
    // user co collateral < amount -> khong rut duoc
    // user co collateral >= amount -> rut duoc
    // true:
    // user co collateral < amount -> rut duoc (phan thieu chuyen thanh khoan vay)
    // user co collateral >= amount -> rut binh thuong

    public entry fun withdraw(
        owner_signer: &signer,
        amount: u64
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);

        controller::withdraw<AptosCoin>(
            owner_signer,
            NAME_BYTES,
            amount,
            false
        );
    }

    //

    //Echelon framework
}